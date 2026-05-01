import 'package:flutter/material.dart';
import '../../services/database_credential_service.dart';

class DatabaseSettingsView extends StatefulWidget {
  const DatabaseSettingsView({super.key});

  @override
  State<DatabaseSettingsView> createState() => _DatabaseSettingsViewState();
}

class _DatabaseSettingsViewState extends State<DatabaseSettingsView> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _portController = TextEditingController(text: '5432');
  final _databaseController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _useSSL = false;
  bool _isLoading = false;
  bool _hasCredentials = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  Future<void> _loadExistingCredentials() async {
    setState(() => _isLoading = true);
    try {
      final credentials = await DatabaseCredentialService.getCredentials();
      if (credentials != null) {
        setState(() {
          _serverController.text = credentials.server;
          _portController.text = credentials.port.toString();
          _databaseController.text = credentials.database;
          _usernameController.text = credentials.username;
          _passwordController.text = '••••••••'; // Masked password
          _useSSL = credentials.useSSL;
          _hasCredentials = true;
        });
      }
    } catch (e) {
      print('Error loading credentials: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);
    
    try {
      final credentials = DatabaseCredentials(
        server: _serverController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 5432,
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        useSSL: _useSSL,
      );

      final isValid = await DatabaseCredentialService.testConnection(credentials);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isValid 
            ? 'Connection successful!' 
            : 'Connection failed. Please check your credentials.'),
          backgroundColor: isValid ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isTesting = false);
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      // If password is masked, don't update it
      String password = _passwordController.text;
      if (password == '••••••••' && _hasCredentials) {
        // Get existing credentials to preserve password
        final existing = await DatabaseCredentialService.getCredentials();
        if (existing != null) {
          password = existing.password;
        }
      }

      final credentials = DatabaseCredentials(
        server: _serverController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 5432,
        database: _databaseController.text.trim(),
        username: _usernameController.text.trim(),
        password: password,
        useSSL: _useSSL,
      );

      await DatabaseCredentialService.saveCredentials(credentials);
      
      if (!mounted) return;
      
      setState(() => _hasCredentials = true);
      _passwordController.text = '••••••••';
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database credentials saved securely!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving credentials: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCredentials() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Delete Credentials?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete the saved database credentials?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await DatabaseCredentialService.deleteCredentials();
      
      if (!mounted) return;
      
      setState(() {
        _hasCredentials = false;
        _serverController.clear();
        _portController.text = '5432';
        _databaseController.clear();
        _usernameController.clear();
        _passwordController.clear();
        _useSSL = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Credentials deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting credentials: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _databaseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text('Database Connection'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading && !_hasCredentials
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Security Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Secure Storage',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Credentials are encrypted and stored in Windows Credential Manager',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Server
                  TextFormField(
                    controller: _serverController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Server / Host',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '192.168.1.100 or postgres.example.com',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066FF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter server address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Port
                  TextFormField(
                    controller: _portController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: '5432',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066FF)),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter port number';
                      }
                      final port = int.tryParse(value.trim());
                      if (port == null || port < 1 || port > 65535) {
                        return 'Please enter a valid port (1-65535)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Database
                  TextFormField(
                    controller: _databaseController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Database Name',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'flowspace',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066FF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter database name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Username
                  TextFormField(
                    controller: _usernameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: Colors.white70),
                      hintText: 'postgres',
                      hintStyle: TextStyle(color: Colors.white38),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066FF)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintText: _hasCredentials ? '••••••••' : 'Enter password',
                      hintStyle: const TextStyle(color: Colors.white38),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0066FF)),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter password';
                      }
                      return null;
                    },
                    onTap: () {
                      if (_hasCredentials && _passwordController.text == '••••••••') {
                        _passwordController.clear();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // SSL Toggle
                  SwitchListTile(
                    title: const Text(
                      'Use SSL/TLS',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Encrypt database connection',
                      style: TextStyle(color: Colors.white54),
                    ),
                    value: _useSSL,
                    onChanged: (value) {
                      setState(() => _useSSL = value);
                    },
                    activeColor: const Color(0xFF0066FF),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading || _isTesting ? null : _testConnection,
                          icon: _isTesting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                          label: const Text('Test Connection'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _isLoading || _isTesting ? null : _saveCredentials,
                          icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.save),
                          label: const Text('Save Credentials'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0066FF),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_hasCredentials) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _deleteCredentials,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete Credentials'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
    );
  }
}

