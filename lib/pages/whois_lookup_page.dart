// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors_in_immutables, library_private_types_in_public_api, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';

/// Stateful widget for WHOIS lookup page
class WhoisLookupPage extends StatefulWidget {
  final String? initialDomain;

  WhoisLookupPage({this.initialDomain});

  @override
  _WhoisLookupPageState createState() => _WhoisLookupPageState();
}

/// State class for WhoisLookupPage
class _WhoisLookupPageState extends State<WhoisLookupPage> {
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _whoisInfo = '';
  bool _isLoading = false;
  bool _showSearchBox = false;
  List<Map<String, String>> _whoisData = [];
  List<Map<String, String>> _filteredWhoisData = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialDomain != null) {
      _domainController.text = widget.initialDomain!;
      _lookupWhois();
    }
  }

  /// Performs WHOIS lookup for the entered domain
  Future<void> _lookupWhois() async {
    final domain = _domainController.text.trim();
    if (domain.isEmpty) {
      setState(() {
        _whoisInfo = 'Please enter a domain name';
      });
      return;
    }

    final cleanedDomain = domain.replaceAll(RegExp(r'^https?://'), '');

    setState(() {
      _isLoading = true;
      _whoisInfo = '';
      _whoisData = [];
      _filteredWhoisData = [];
      _showSearchBox = false;
    });

    try {
      const whoisServer = 'whois.iana.org';
      final ianaResponse = await _queryWhoisServer(whoisServer, cleanedDomain);

      final tldWhoisServer = _extractWhoisServer(ianaResponse);
      if (tldWhoisServer != null) {
        final response = await _queryWhoisServer(tldWhoisServer, cleanedDomain);
        setState(() {
          _whoisInfo = response;
          _isLoading = false;
          _whoisData = _parseWhoisData(response);
          _filteredWhoisData = _whoisData;
          _showSearchBox = true;
        });
        await _saveDomain(domain);
      } else {
        setState(() {
          _whoisInfo = 'WHOIS server not found for the domain.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _whoisInfo = 'Failed to fetch WHOIS info: $e';
        _isLoading = false;
      });
    }
  }

  /// Saves the domain to secure storage
  Future<void> _saveDomain(String domain) async {
    List<String> domains = await _getSavedDomains();
    if (!domains.contains(domain)) {
      domains.add(domain);
      await _storage.write(key: 'domains', value: domains.join(','));
    }
  }

  /// Retrieves the list of saved domains from secure storage
  Future<List<String>> _getSavedDomains() async {
    String? domainsString = await _storage.read(key: 'domains');
    if (domainsString != null) {
      return domainsString.split(',');
    }
    return [];
  }

  /// Queries the WHOIS server for the given domain
  Future<String> _queryWhoisServer(String server, String domain) async {
    final socket = await Socket.connect(server, 43);
    socket.writeln(domain);
    await socket.flush();

    final response = StringBuffer();
    await socket.listen((List<int> data) {
      response.write(String.fromCharCodes(data));
    }).asFuture();

    socket.close();
    return response.toString();
  }

  /// Extracts the WHOIS server address from the response data
  String? _extractWhoisServer(String data) {
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('whois:')) {
        return line.split(':')[1].trim();
      }
    }
    return null;
  }

  /// Parses the WHOIS data into a list of key-value pairs
  List<Map<String, String>> _parseWhoisData(String data) {
    final lines = data.split('\n');
    final List<Map<String, String>> parsedData = [];
    for (var line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          parsedData.add({
            'field': parts[0].trim(),
            'value': parts.sublist(1).join(':').trim(),
          });
        }
      }
    }
    return parsedData;
  }

  /// Filters the WHOIS data based on the search query
  void _filterWhoisData(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredWhoisData = _whoisData;
      });
      return;
    }

    setState(() {
      _filteredWhoisData = _whoisData
          .where((data) =>
              data['field']!.toLowerCase().contains(query.toLowerCase()) ||
              data['value']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Displays a modal dialog with the given WHOIS entry
  void _showModal(BuildContext context, Map<String, String> entry) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(entry['field']!),
          content: Text(entry['value']!),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Copy'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: entry['value']!));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WHOIS Lookup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter a domain name to lookup WHOIS information:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: 'Domain name',
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _lookupWhois,
                child: Text('Lookup WHOIS'),
              ),
            ),
            SizedBox(height: 20),
            _showSearchBox
                ? Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search WHOIS data',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _filterWhoisData,
                      ),
                      SizedBox(height: 20),
                    ],
                  )
                : Container(),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredWhoisData.isNotEmpty
                    ? Expanded(
                        child: ListView.builder(
                          itemCount: _filteredWhoisData.length,
                          itemBuilder: (context, index) {
                            final entry = _filteredWhoisData[index];
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                title: Text(
                                  entry['field']!,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(entry['value']!),
                                onTap: () => _showModal(context, entry),
                              ),
                            );
                          },
                        ),
                      )
                    : _whoisInfo.isNotEmpty
                        ? Expanded(
                            child: SingleChildScrollView(
                              child: Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  _whoisInfo,
                                  style: TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ),
                          )
                        : Container(),
          ],
        ),
      ),
    );
  }
}
