import 'dart:io';
import 'package:lua_dardo_co/lua.dart';
import 'package:logging/logging.dart';

/// Wrapper around Lua VM for executing Lua scripts
///
/// This class provides a high-level interface to the Lua scripting engine.
/// It handles:
/// - Lua state initialization
/// - Standard library loading
/// - Custom binding registration
/// - Script execution (from string or file)
/// - Function calling
/// - Proper cleanup and disposal
class LuaEngine {
  static final _logger = Logger('LuaEngine');

  LuaState? _state;
  bool _isInitialized = false;

  /// Whether the Lua engine has been initialized
  bool get isInitialized => _isInitialized;

  /// Get the underlying Lua state (for advanced usage)
  LuaState? get state => _state;

  /// Initialize the Lua VM
  ///
  /// Creates a new Lua state, opens standard libraries, and registers
  /// custom bindings. This must be called before using any other methods.
  ///
  /// Throws [StateError] if already initialized.
  Future<void> initialize() async {
    if (_isInitialized) {
      throw StateError('LuaEngine is already initialized');
    }

    try {
      _logger.info('Initializing Lua engine');

      // Create new Lua state
      _state = LuaState.newState();

      // Open standard Lua libraries
      _state!.openLibs();

      _isInitialized = true;
      _logger.info('Lua engine initialized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize Lua engine', e, stackTrace);
      rethrow;
    }
  }

  /// Execute a Lua script from a string
  ///
  /// Runs the provided Lua code and returns the result.
  /// If the script has multiple return values, returns a list.
  /// If the script has a single return value, returns that value.
  /// If the script has no return value, returns null.
  ///
  /// [script] The Lua code to execute
  /// Returns the result of the script execution
  ///
  /// Throws [StateError] if not initialized
  /// Throws [LuaException] if script execution fails
  dynamic executeScript(String script) {
    _ensureInitialized();

    try {
      final preview = script.length > 100 ? script.substring(0, 100) : script;
      _logger.fine('Executing Lua script: $preview...');

      // Load and execute the script using doString which handles both loading and execution
      final status = _state!.doString(script);
      if (status == false) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(1);
        throw LuaException('Script execution failed: $error');
      }

      // Get the results from the stack
      final top = _state!.getTop();
      if (top == 0) {
        return null; // No return values
      } else if (top == 1) {
        final result = _getStackValue(-1);
        _state!.pop(1);
        return result;
      } else {
        // Multiple return values
        final results = <dynamic>[];
        for (var i = 1; i <= top; i++) {
          results.add(_getStackValue(i));
        }
        _state!.pop(top);
        return results;
      }
    } catch (e) {
      if (e is LuaException) rethrow;
      _logger.severe('Error executing script', e);
      throw LuaException('Script execution error: $e');
    }
  }

  /// Execute a Lua script from a file
  ///
  /// Reads the file contents and executes it as Lua code.
  ///
  /// [filePath] The path to the Lua script file
  /// Returns the result of the script execution
  ///
  /// Throws [StateError] if not initialized
  /// Throws [FileSystemException] if file cannot be read
  /// Throws [LuaException] if script execution fails
  Future<dynamic> executeFile(String filePath) async {
    _ensureInitialized();

    try {
      _logger.info('Executing Lua file: $filePath');

      final file = File(filePath);
      if (!await file.exists()) {
        throw FileSystemException('Script file not found', filePath);
      }

      final script = await file.readAsString();
      return executeScript(script);
    } catch (e) {
      if (e is LuaException || e is FileSystemException) rethrow;
      _logger.severe('Error executing file', e);
      throw LuaException('File execution error: $e');
    }
  }

  /// Call a Lua function by name
  ///
  /// Calls a global Lua function with the provided arguments.
  /// Arguments are automatically converted to appropriate Lua types.
  /// Supported argument types: int, double, bool, String, List, Map, null
  ///
  /// [functionName] The name of the Lua function to call
  /// [args] The arguments to pass to the function (defaults to empty list)
  /// Returns the result of the function call
  ///
  /// Throws [StateError] if not initialized
  /// Throws [LuaException] if function doesn't exist or call fails
  dynamic callFunction(String functionName, [List<dynamic> args = const []]) {
    _ensureInitialized();

    try {
      _logger.fine(
        'Calling Lua function: $functionName with ${args.length} args',
      );

      // Get the global function
      _state!.getGlobal(functionName);
      if (!_state!.isFunction(-1)) {
        _state!.pop(1);
        throw LuaException('Function "$functionName" not found');
      }

      // Push arguments onto the stack
      for (final arg in args) {
        _pushValue(arg);
      }

      // Call the function
      final pcallStatus = _state!.pCall(args.length, 1, 0);
      if (pcallStatus != ThreadStatus.luaOk) {
        final error = _state!.toStr(-1) ?? 'Unknown error';
        _state!.pop(1);
        throw LuaException('Function call failed: $error');
      }

      // Get the result
      final result = _getStackValue(-1);
      _state!.pop(1);

      return result;
    } catch (e) {
      if (e is LuaException) rethrow;
      _logger.severe('Error calling function', e);
      throw LuaException('Function call error: $e');
    }
  }

  /// Register a Dart function as a global Lua function
  ///
  /// Makes a Dart function callable from Lua scripts.
  /// The Dart function should accept a LuaState parameter and return
  /// the number of return values pushed onto the stack.
  ///
  /// [name] The name of the function in Lua
  /// [function] The Dart function to register
  ///
  /// Throws [StateError] if not initialized
  void registerFunction(String name, int Function(LuaState) function) {
    _ensureInitialized();

    try {
      _logger.fine('Registering Lua function: $name');
      _state!.register(name, function);
    } catch (e) {
      _logger.severe('Error registering function', e);
      throw LuaException('Function registration error: $e');
    }
  }

  /// Set a global variable in Lua
  ///
  /// [name] The name of the global variable
  /// [value] The value to set
  ///
  /// Throws [StateError] if not initialized
  void setGlobal(String name, dynamic value) {
    _ensureInitialized();

    try {
      _pushValue(value);
      _state!.setGlobal(name);
    } catch (e) {
      _logger.severe('Error setting global', e);
      throw LuaException('Set global error: $e');
    }
  }

  /// Get a global variable from Lua
  ///
  /// [name] The name of the global variable
  /// Returns the value of the global variable
  ///
  /// Throws [StateError] if not initialized
  dynamic getGlobal(String name) {
    _ensureInitialized();

    try {
      _state!.getGlobal(name);
      final result = _getStackValue(-1);
      _state!.pop(1);
      return result;
    } catch (e) {
      _logger.severe('Error getting global', e);
      throw LuaException('Get global error: $e');
    }
  }

  /// Dispose of the Lua engine
  ///
  /// Releases all resources.
  /// After calling this, the engine cannot be used until re-initialized.
  void dispose() {
    if (!_isInitialized) return;

    try {
      _logger.info('Disposing Lua engine');
      _state = null;
      _isInitialized = false;
      _logger.info('Lua engine disposed');
    } catch (e) {
      _logger.severe('Error disposing Lua engine', e);
    }
  }

  // Private helper methods

  /// Ensure the engine is initialized
  void _ensureInitialized() {
    if (!_isInitialized || _state == null) {
      throw StateError(
        'LuaEngine is not initialized. Call initialize() first.',
      );
    }
  }

  /// Push a Dart value onto the Lua stack
  void _pushValue(dynamic value) {
    if (value == null) {
      _state!.pushNil();
    } else if (value is bool) {
      _state!.pushBoolean(value);
    } else if (value is int) {
      _state!.pushInteger(value);
    } else if (value is double) {
      _state!.pushNumber(value);
    } else if (value is String) {
      _state!.pushString(value);
    } else if (value is List) {
      _pushList(value);
    } else if (value is Map) {
      _pushMap(value);
    } else {
      throw LuaException('Unsupported value type: ${value.runtimeType}');
    }
  }

  /// Push a Dart list as a Lua table
  void _pushList(List<dynamic> list) {
    _state!.newTable();
    for (var i = 0; i < list.length; i++) {
      _state!.pushInteger(i + 1); // Lua arrays are 1-indexed
      _pushValue(list[i]);
      _state!.setTable(-3);
    }
  }

  /// Push a Dart map as a Lua table
  void _pushMap(Map<dynamic, dynamic> map) {
    _state!.newTable();
    for (final entry in map.entries) {
      _pushValue(entry.key);
      _pushValue(entry.value);
      _state!.setTable(-3);
    }
  }

  /// Get a value from the Lua stack at the given index
  dynamic _getStackValue(int index) {
    if (_state!.isNil(index)) {
      return null;
    } else if (_state!.isBoolean(index)) {
      return _state!.toBoolean(index);
    } else if (_state!.isInteger(index)) {
      return _state!.toInteger(index);
    } else if (_state!.isNumber(index)) {
      return _state!.toNumber(index);
    } else if (_state!.isString(index)) {
      return _state!.toStr(index);
    } else if (_state!.isTable(index)) {
      return _getTable(index);
    } else {
      return null; // Unsupported type
    }
  }

  /// Convert a Lua table to a Dart Map or List
  dynamic _getTable(int index) {
    final result = <dynamic, dynamic>{};
    var isArray = true;
    var arrayIndex = 1;

    _state!.pushNil(); // First key
    while (_state!.next(index < 0 ? index - 1 : index)) {
      // Check if this is an array-style table (consecutive integer keys starting from 1)
      if (isArray) {
        if (_state!.isInteger(-2)) {
          final key = _state!.toInteger(-2);
          if (key != arrayIndex) {
            isArray = false;
          } else {
            arrayIndex++;
          }
        } else {
          isArray = false;
        }
      }

      final key = _getStackValue(-2);
      final value = _getStackValue(-1);
      result[key] = value;

      _state!.pop(1); // Remove value, keep key for next iteration
    }

    // Convert to List if it's an array-style table
    if (isArray && result.isNotEmpty) {
      final list = <dynamic>[];
      for (var i = 1; i <= result.length; i++) {
        list.add(result[i]);
      }
      return list;
    }

    return result;
  }
}

/// Exception thrown by Lua engine operations
class LuaException implements Exception {
  final String message;

  LuaException(this.message);

  @override
  String toString() => 'LuaException: $message';
}
