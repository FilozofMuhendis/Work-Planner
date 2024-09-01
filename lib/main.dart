import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';  // Eklenen bu satır
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

void main() async {
  await initializeDateFormatting('tr_TR', null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planlayıcı',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // yearlyPlans listesini burada tanımlıyoruz
  List<Map<String, dynamic>> yearlyPlans = [];

  @override
  void initState() {
    super.initState();
    _loadYearlyPlans();
  }

  Future<void> _loadYearlyPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];
    List<Map<String, dynamic>> loadedPlans = [];

    for (String plan in savedPlans) {
      try {
        Map<String, dynamic> decodedPlan = jsonDecode(plan);
        if (decodedPlan['type'] == 'Yıllık') {
          loadedPlans.add(decodedPlan);
        }
      } catch (e) {
        print('Hata: $e');
      }
    }

    setState(() {
      yearlyPlans = loadedPlans;
    });
  }

  final List<Widget> _pages = [
    Anasayfa(yearlyPlans: [],), // Anasayfa'ya yıllık planları iletmek gerekiyor
    AddPlanPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planlayıcı'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Profil sayfasına yönlendirme
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Plan Ekle',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class Anasayfa extends StatelessWidget {
  final List<Map<String, dynamic>> yearlyPlans;

  const Anasayfa({super.key, required this.yearlyPlans});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş geldiniz',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Bugün ${_getCurrentDate()}',
              style: TextStyle(fontSize: 18, color: Colors.blueGrey),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildPlanCard(
                    context,
                    title: 'Günlük Plan',
                    description: 'Bugünkü görevlerinizi burada görün.',
                    icon: Icons.calendar_today,
                    color: Colors.blue,
                  ),
                  _buildPlanCard(
                    context,
                    title: 'Haftalık Plan',
                    description: 'Bu hafta için belirlenen görevler.',
                    icon: Icons.calendar_view_week,
                    color: Colors.orange,
                  ),
                  _buildPlanCard(
                    context,
                    title: 'Yıllık Plan',
                    description: 'Yılın geri kalanındaki önemli etkinlikler.',
                    icon: Icons.calendar_today,
                    color: Colors.green,
                  ),
                  _buildUpcomingPlansSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context,
      {required String title,
        required String description,
        required IconData icon,
        required Color color}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        onTap: () {
          if (title == 'Günlük Plan') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DailyPlansPage()),
            );
          } else if (title == 'Haftalık Plan') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WeeklyPlansPage()),
            );
          } else if (title == 'Yıllık Plan') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => YearlyPlansPage()),
            );
          }
        },
      ),
    );
  }

  Widget _buildUpcomingPlansSection() {
    DateTime now = DateTime.now();
    DateTime oneDayFromNow = now.add(Duration(hours: 24));
    DateTime oneHourFromNow = now.add(Duration(hours: 1));

    List<Map<String, dynamic>> upcomingPlans = yearlyPlans.where((plan) {
      DateTime planDate = DateTime.parse(plan['date']);
      return planDate.isAfter(now) && planDate.isBefore(oneDayFromNow);
    }).toList();

    List<Map<String, dynamic>> upcomingPlansInOneHour = yearlyPlans.where((plan) {
      DateTime planDate = DateTime.parse(plan['date']);
      String planTime = plan['time'];
      DateTime planDateTime = DateTime(
        planDate.year,
        planDate.month,
        planDate.day,
        int.parse(planTime.split(':')[0]),
        int.parse(planTime.split(':')[1]),
      );
      return planDateTime.isAfter(now) && planDateTime.isBefore(oneHourFromNow);
    }).toList();

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son 24 Saat İçinde Yaklaşan Planlar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          upcomingPlans.isEmpty
              ? Text('Son 24 saat içinde plan bulunmamaktadır.')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: upcomingPlans.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(upcomingPlans[index]['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcomingPlans[index]['description']),
                      Text(
                          'Tarih: ${DateFormat.yMd().format(DateTime.parse(upcomingPlans[index]['date']))}'),
                      Text('Saat: ${upcomingPlans[index]['time']}'),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 20),
          Text(
            'Son 1 Saat İçinde Yaklaşan Planlar',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          upcomingPlansInOneHour.isEmpty
              ? Text('Son 1 saat içinde plan bulunmamaktadır.')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: upcomingPlansInOneHour.length,
            itemBuilder: (context, index) {
              return Card(
                child: ListTile(
                  title: Text(upcomingPlansInOneHour[index]['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upcomingPlansInOneHour[index]['description']),
                      Text(
                          'Tarih: ${DateFormat.yMd().format(DateTime.parse(upcomingPlansInOneHour[index]['date']))}'),
                      Text('Saat: ${upcomingPlansInOneHour[index]['time']}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        margin: EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(title,
                  style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(value,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class AddPlanPage extends StatefulWidget {
  @override
  _AddPlanPageState createState() => _AddPlanPageState();
}

// Yerel depolama anahtarı
const String _planStorageKey = 'saved_plans';

class _AddPlanPageState extends State<AddPlanPage> {
  final _formKey = GlobalKey<FormState>();
  String _planName = '';
  String _planDescription = '';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _planType = 'Günlük';

  Future<void> _savePlanAndNavigate() async {
    if (_formKey.currentState!.validate()) {
      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];

        Map<String, dynamic> newPlan = {
          'name': _planName,
          'description': _planDescription,
          'date': _selectedDate.toIso8601String(),
          'time': _selectedTime.format(context),
          'type': _planType,
        };

        // Planı JSON string'ine dönüştürerek kaydet
        savedPlans.add(jsonEncode(newPlan));
        bool isSaved = await prefs.setStringList(_planStorageKey, savedPlans);

        if (isSaved) {
          // Kaydetme başarılı olursa, ilgili plan sayfasına yönlendir
          if (_planType == 'Günlük') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DailyPlansPage()),
            );
          } else if (_planType == 'Haftalık') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => WeeklyPlansPage()),
            );
          } else if (_planType == 'Yıllık') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => YearlyPlansPage()),
            );
          }
        } else {
          print('Plan kaydedilemedi');
        }
      } catch (e) {
        print('Hata oluştu: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan Ekle'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Plan Adı'),
                onChanged: (value) {
                  setState(() {
                    _planName = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen plan adı giriniz';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Plan Açıklaması'),
                maxLines: 3,
                onChanged: (value) {
                  setState(() {
                    _planDescription = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen plan açıklaması giriniz';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ListTile(
                title: Text('Tarih: ${DateFormat.yMd().format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
              ListTile(
                title: Text('Saat: ${_selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: _selectTime,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Plan Türü'),
                value: _planType,
                items: <String>['Günlük', 'Haftalık', 'Yıllık']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _planType = value!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePlanAndNavigate, // Metodu burada çağırıyoruz
                child: Text('Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    TimeOfDay? picked =
    await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
}

class DailyPlansPage extends StatefulWidget {
  @override
  _DailyPlansPageState createState() => _DailyPlansPageState();
}

class _DailyPlansPageState extends State<DailyPlansPage> {
  List<Map<String, dynamic>> dailyPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];
    List<Map<String, dynamic>> loadedPlans = [];

    for (String plan in savedPlans) {
      try {
        Map<String, dynamic> decodedPlan = jsonDecode(plan);
        print('Decoded Plan: $decodedPlan'); // Debug için kontrol edin

        if (decodedPlan['type'] == 'Günlük') {
          loadedPlans.add(decodedPlan);
        }
      } catch (e) {
        print('Hata: $e');
      }
    }

    setState(() {
      dailyPlans = loadedPlans;
    });
  }



  void _deletePlan(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];

    savedPlans.removeAt(index);

    await prefs.setStringList(_planStorageKey, savedPlans);
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Günlük Planlar'),
      ),
      body: ListView.builder(
        itemCount: dailyPlans.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(dailyPlans[index]['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dailyPlans[index]['description']),
                  Text(
                      'Tarih: ${DateFormat.yMd().format(DateTime.parse(dailyPlans[index]['date']))}'),
                  Text('Saat: ${dailyPlans[index]['time']}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deletePlan(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class WeeklyPlansPage extends StatefulWidget {
  @override
  _WeeklyPlansPageState createState() => _WeeklyPlansPageState();
}

class _WeeklyPlansPageState extends State<WeeklyPlansPage> {
  List<Map<String, dynamic>> weeklyPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];
    List<Map<String, dynamic>> loadedPlans = [];

    for (String plan in savedPlans) {
      try {
        Map<String, dynamic> decodedPlan = jsonDecode(plan);
        print('Decoded Plan: $decodedPlan'); // Debug için kontrol edin

        if (decodedPlan['type'] == 'Haftalık') {
          loadedPlans.add(decodedPlan);
        }
      } catch (e) {
        print('Hata: $e');
      }
    }

    setState(() {
      weeklyPlans = loadedPlans;
    });
  }

  void _deletePlan(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];

    savedPlans.removeAt(index);

    await prefs.setStringList(_planStorageKey, savedPlans);
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Haftalık Planlar'),
      ),
      body: ListView.builder(
        itemCount: weeklyPlans.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(weeklyPlans[index]['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weeklyPlans[index]['description']),
                  Text(
                      'Tarih: ${DateFormat.yMd().format(DateTime.parse(weeklyPlans[index]['date']))}'),
                  Text('Saat: ${weeklyPlans[index]['time']}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deletePlan(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}


class YearlyPlansPage extends StatefulWidget {
  @override
  _YearlyPlansPageState createState() => _YearlyPlansPageState();
}

class _YearlyPlansPageState extends State<YearlyPlansPage> {
  List<Map<String, dynamic>> yearlyPlans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];
    List<Map<String, dynamic>> loadedPlans = [];

    for (String plan in savedPlans) {
      try {
        Map<String, dynamic> decodedPlan = jsonDecode(plan);
        print('Decoded Plan: $decodedPlan'); // Debug için kontrol edin

        if (decodedPlan['type'] == 'Yıllık') {
          loadedPlans.add(decodedPlan);
        }
      } catch (e) {
        print('Hata: $e');
      }
    }

    setState(() {
      yearlyPlans = loadedPlans;
    });
  }

  void _deletePlan(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedPlans = prefs.getStringList(_planStorageKey) ?? [];

    savedPlans.removeAt(index);

    await prefs.setStringList(_planStorageKey, savedPlans);
    _loadPlans();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yıllık Planlar'),
      ),
      body: ListView.builder(
        itemCount: yearlyPlans.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(yearlyPlans[index]['name']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(yearlyPlans[index]['description']),
                  Text(
                      'Tarih: ${DateFormat.yMd().format(DateTime.parse(yearlyPlans[index]['date']))}'),
                  Text('Saat: ${yearlyPlans[index]['time']}'),
                ],
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  _deletePlan(index);
                },
              ),
            ),
          );
        },
      ),
    );
  }
}


String _getCurrentDate() {
  return DateFormat('dd MMMM yyyy', 'tr_TR').format(DateTime.now());
}
