import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  DateTime? _selectedDate;
  bool _messageSaved = false;

  String? savedMessage;
  DateTime? unlockDate;

  @override
  void initState() {
    super.initState();
    _loadSavedMessage();
  }

  void _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now.add(Duration(days: 1)),
      firstDate: now.add(Duration(days: 1)),
      lastDate: now.add(Duration(days: 365 * 5)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a message and pick a future date.')),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('message', _messageController.text.trim());
    await prefs.setString('unlockDate', _selectedDate!.toIso8601String());

    setState(() {
      savedMessage = _messageController.text.trim();
      unlockDate = _selectedDate;
      _messageSaved = true;
    });
  }

  void _loadSavedMessage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final storedMessage = prefs.getString('message');
    final storedDateStr = prefs.getString('unlockDate');

    if (storedMessage != null && storedDateStr != null) {
      final parsedDate = DateTime.tryParse(storedDateStr);
      if (parsedDate != null) {
        setState(() {
          savedMessage = storedMessage;
          unlockDate = parsedDate;
          _messageSaved = true;
        });
      }
    }
  }

  Widget _buildMessageView() {
    final now = DateTime.now();
    bool isLocked = now.isBefore(unlockDate!);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isLocked ? Icons.lock_clock : Icons.lock_open,
          size: 60,
          color: isLocked ? Colors.grey : Colors.indigo,
        ),
        SizedBox(height: 20),
        Text(
          isLocked
              ? 'Your message will unlock in ${unlockDate!.difference(now).inDays} day(s).'
              : savedMessage ?? '',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 40),
        ElevatedButton.icon(
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.clear(); // delete saved data

            setState(() {
              _messageSaved = false;
              savedMessage = null;
              unlockDate = null;
              _messageController.clear();
            });
          },
          icon: Icon(Icons.restart_alt),
          label: Text('Create New Capsule'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Time Capsule')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _messageSaved
            ? _buildMessageView()
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Write a message for your future self:',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 12),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Dear future me...',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? 'No date selected.'
                      : 'Unlocks on: ${DateFormat.yMMMMd().format(_selectedDate!)}',
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: Icon(Icons.calendar_today, color: Colors.white),
                  label: Text('Pick Date'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _saveMessage,
              child: Text('Lock Message'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),

    );
  }
}
