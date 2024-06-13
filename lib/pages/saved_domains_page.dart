// ignore_for_file: library_private_types_in_public_api, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:whois_app/pages/whois_lookup_page.dart';

/// Stateful widget for saved domains page
class SavedDomainsPage extends StatefulWidget {
  @override
  _SavedDomainsPageState createState() => _SavedDomainsPageState();
}

/// State class for SavedDomainsPage
class _SavedDomainsPageState extends State<SavedDomainsPage> {
  final _storage = const FlutterSecureStorage();

  /// Retrieves the list of saved domains from secure storage
  Future<List<String>> _getSavedDomains() async {
    String? domainsString = await _storage.read(key: 'domains');
    if (domainsString != null) {
      return domainsString.split(',');
    }
    return [];
  }

  /// Deletes a domain from secure storage
  Future<void> _deleteDomain(String domain) async {
    List<String> domains = await _getSavedDomains();
    domains.remove(domain);
    await _storage.write(key: 'domains', value: domains.join(','));
    setState(() {});
  }

  /// Shows a confirmation dialog before deleting a domain
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
              onPressed: () {
                _deleteDomain(domain);
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
        title: Text('Saved Domains'),
      ),
      body: FutureBuilder<List<String>>(
        future: _getSavedDomains(),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No saved domains.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (BuildContext context, int index) {
                final domain = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(domain),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        _showDeleteConfirmDialog(context, domain);
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WhoisLookupPage(initialDomain: domain),
                        ),
                      );
                    },
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
