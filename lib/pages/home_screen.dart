// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whois_app/pages/saved_domains_page.dart';
import 'package:whois_app/pages/whois_lookup_page.dart';

/// Home screen of the WHOIS Lookup application
class HomeScreen extends StatelessWidget {
  /// Opens the given URL in the default web browser
  Future<void> _launchURL(String url) async {
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
        centerTitle: true,
        foregroundColor: Colors.blueAccent,
        title: Text('WHO IS APP'),
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
              _launchURL('https://github.com/oguzhan18/whois_app');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey, Colors.blue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(height: 30),
              Center(
                child: Text(
                  'WHOIS Lookup',
                  style: TextStyle(fontSize: 30, color: Colors.white),
                ),
              ),
              SizedBox(height: 100.0),
              ListTile(
                leading: Icon(Icons.search, color: Colors.white),
                title:
                    Text('WHOIS Lookup', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WhoisLookupPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.list, color: Colors.white),
                title: Text('Saved Domains',
                    style: TextStyle(color: Colors.white)),
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
                    color: Colors.blue),
              ),
              SizedBox(height: 20),
              Text(
                'This application allows you to perform WHO IS lookups for any domain. '
                'You can search for detailed information about domain registrations, '
                'such as the registrar, registration date, and contact information.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 20),
              Text(
                'Features:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '- Quick and easy WHO IS lookups\n'
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
                child: Text('Start WHO IS Lookup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
