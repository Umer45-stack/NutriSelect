import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class UserAnalyticsDashboard extends StatefulWidget {
  @override
  _UserAnalyticsDashboardState createState() => _UserAnalyticsDashboardState();
}

class _UserAnalyticsDashboardState extends State<UserAnalyticsDashboard> {
  int totalUsers = 0;
  int vendorCount = 0;
  int regularCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot allUsersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      QuerySnapshot vendorSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'vendor').get();
      QuerySnapshot regularSnapshot = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'user').get();

      setState(() {
        totalUsers = allUsersSnapshot.docs.length;
        vendorCount = vendorSnapshot.docs.length;
        regularCount = regularSnapshot.docs.length;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching analytics: $error");
    }
  }

  List<PieChartSectionData> _getPieChartSections() {
    final double total = totalUsers.toDouble();
    if (total == 0) return [];
    return [
      PieChartSectionData(
        value: vendorCount.toDouble(),
        title: 'Vendors\n${((vendorCount / total) * 100).toStringAsFixed(1)}%',
        color: Colors.green,
        radius: 60,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: regularCount.toDouble(),
        title: 'Users\n${((regularCount / total) * 100).toStringAsFixed(1)}%',
        color: Colors.blue,
        radius: 60,
        titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];
  }

  List<BarChartGroupData> _getBarChartData() {
    return [
      BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 5, color: Colors.orange, width: 16)]),
      BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 8, color: Colors.orange, width: 16)]),
      BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 6, color: Colors.orange, width: 16)]),
      BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 10, color: Colors.orange, width: 16)]),
      BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 7, color: Colors.orange, width: 16)]),
      BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 9, color: Colors.orange, width: 16)]),
    ];
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        barGroups: _getBarChartData(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2,
              getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                int index = value.toInt() - 1;
                return index >= 0 && index < months.length
                    ? Text(months[index])
                    : SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Analytics Dashboard'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : totalUsers == 0
          ? Center(child: Text('No users found.'))
          : RefreshIndicator(
        onRefresh: fetchAnalytics,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Text(
              'User Role Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: _getPieChartSections(),
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Monthly Signups',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 300,
              child: _buildBarChart(),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                'Total Users: $totalUsers',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
