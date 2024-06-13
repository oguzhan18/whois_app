// ignore_for_file: sort_child_properties_last, prefer_const_constructors

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WHOIS Lookup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        hintColor: Colors.lightBlueAccent,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('WHOIS Lookup'),
        actions: [
          IconButton(
            icon: Icon(Icons.web),
            onPressed: () {
              _launchURL('https://oguzhancart.dev/');
            },
          ),
          IconButton(
            icon: Icon(Icons.code),
            onPressed: () {
              _launchURL('https://github.com/yourrepository');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.blue),
              title: Text('WHOIS Lookup'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WhoisLookupPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.list, color: Colors.blue),
              title: Text('Saved Domains'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SavedDomainsPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to WHOIS Lookup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'This application allows you to perform WHOIS lookups for any domain. '
                'You can search for detailed information about domain registrations, '
                'such as the registrar, registration date, and contact information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Features:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '- Quick and easy WHOIS lookups\n'
                '- Save your search results\n'
                '- View previously saved domains\n'
                '- Simple and intuitive interface',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WhoisLookupPage()),
                  );
                },
                child: Text('Start WHOIS Lookup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WhoisLookupPage extends StatefulWidget {
  final String? initialDomain;

  WhoisLookupPage({this.initialDomain});

  @override
  _WhoisLookupPageState createState() => _WhoisLookupPageState();
}

class _WhoisLookupPageState extends State<WhoisLookupPage> {
  final TextEditingController _domainController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final _storage = FlutterSecureStorage();
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
      final whoisServer = 'whois.iana.org';
      final ianaResponse = await _queryWhoisServer(whoisServer, cleanedDomain);

      final tldWhoisServer = _extractWhoisServer(ianaResponse);
      if (tldWhoisServer != null) {
        final response = await _queryWhoisServer(tldWhoisServer, cleanedDomain);
        print(response);
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

  Future<void> _saveDomain(String domain) async {
    List<String> domains = await _getSavedDomains();
    if (!domains.contains(domain)) {
      domains.add(domain);
      await _storage.write(key: 'domains', value: domains.join(','));
    }
  }

  Future<List<String>> _getSavedDomains() async {
    String? domainsString = await _storage.read(key: 'domains');
    if (domainsString != null) {
      return domainsString.split(',');
    }
    return [];
  }

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

  String? _extractWhoisServer(String data) {
    final lines = data.split('\n');
    for (var line in lines) {
      if (line.toLowerCase().startsWith('whois:')) {
        return line.split(':')[1].trim();
      }
    }
    return null;
  }

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
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a domain name to lookup WHOIS information:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _domainController,
              decoration: InputDecoration(
                labelText: 'Domain name',
                border: OutlineInputBorder(),
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

class SavedDomainsPage extends StatefulWidget {
  @override
  _SavedDomainsPageState createState() => _SavedDomainsPageState();
}

class _SavedDomainsPageState extends State<SavedDomainsPage> {
  final _storage = FlutterSecureStorage();

  Future<List<String>> _getSavedDomains() async {
    String? domainsString = await _storage.read(key: 'domains');
    if (domainsString != null) {
      return domainsString.split(',');
    }
    return [];
  }

  Future<void> _deleteDomain(String domain) async {
    List<String> domains = await _getSavedDomains();
    domains.remove(domain);
    await _storage.write(key: 'domains', value: domains.join(','));
    setState(() {});
  }

  void _showDeleteConfirmDialog(BuildContext context, String domain) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content:
              Text('Are you sure you want to delete the domain "$domain"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await _deleteDomain(domain);
                Navigator.of(context).pop();
                setState(() {});
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
        title: Text('Saved Domains'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getSavedDomains(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading saved domains'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No saved domains'));
          } else {
            final domains = snapshot.data!;
            return ListView.builder(
              itemCount: domains.length,
              itemBuilder: (context, index) {
                final domain = domains[index];
                return ListTile(
                  title: Text(domain),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () {
                          _showDeleteConfirmDialog(context, domain);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WhoisLookupPage(initialDomain: domain),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
