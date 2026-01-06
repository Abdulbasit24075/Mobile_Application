import 'package:flutter/material.dart';
import 'package:weather_app/widgets/weather_widget_provider.dart';
import 'package:weather_app/services/weather_widget_manager.dart';

class WidgetConfigurationScreen extends StatefulWidget {
  const WidgetConfigurationScreen({super.key});

  @override
  State<WidgetConfigurationScreen> createState() => _WidgetConfigurationScreenState();
}

class _WidgetConfigurationScreenState extends State<WidgetConfigurationScreen> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = true;
  bool _isUpdating = false;
  Map<String, dynamic> _currentConfig = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentConfiguration();
  }

  Future<void> _loadCurrentConfiguration() async {
    setState(() => _isLoading = true);
    try {
      final config = await WeatherWidgetProvider.getConfiguration();
      setState(() {
        _currentConfig = config;
        _cityController.text = config['city'] ?? 'Lahore';
      });
    } catch (e) {
      print('Error loading config: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfiguration() async {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a city name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await WeatherWidgetManager.updateWidgetWithCity(_cityController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget configuration saved!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload the configuration
      await _loadCurrentConfiguration();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving configuration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateWidgetNow() async {
    setState(() => _isUpdating = true);
    try {
      await WeatherWidgetProvider.updateWidget();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Widget updated!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating widget: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Configuration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Configuration Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text('City: ${_currentConfig['city'] ?? 'Not set'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.thermostat),
                      title: Text('Temperature: ${_currentConfig['temperature'] ?? '--°C'}'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.cloud),
                      title: Text('Condition: ${_currentConfig['condition'] ?? 'Not set'}'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Configuration Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configure Widget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City Name',
                        hintText: 'e.g., Lahore, Karachi',
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isUpdating ? null : _saveConfiguration,
                        icon: _isUpdating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Icon(Icons.save),
                        label: Text(_isUpdating ? 'Saving...' : 'Save Configuration'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Update Widget Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUpdating ? null : _updateWidgetNow,
                icon: const Icon(Icons.refresh),
                label: const Text('Update Widget Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.blueAccent,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '1. Configure your city above\n'
                          '2. Save the configuration\n'
                          '3. Add the widget to your home screen\n'
                          '4. Tap "Update Widget Now" to refresh',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}