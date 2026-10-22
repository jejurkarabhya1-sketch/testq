import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'database.dart';

void main() => runApp(const LasalgaonApp());
String money(Object? v) => NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:0).format(n(v));
const departments=['ग्रामनिधी','पाणी पुरवठा'];
const monthNames=['जानेवारी','फेब्रुवारी','मार्च','एप्रिल','मे','जून','जुलै','ऑगस्ट','सप्टेंबर','ऑक्टोबर','नोव्हेंबर','डिसेंबर'];
const salaryFields=<String,String>{'basic':'मूळ वेतन','leave_salary':'रजा वेतन','substitution_salary':'स्थानार्पण वेतन','da':'महागाई / सानुग्रह अनुदान','future_payable':'पुढील अधिदानासाठी ठेवलेली रक्कम','recovery_days':'वसुली दिवस','loan':'हप्ता / कर्ज','insurance':'विमा','festival_advance':'सन अग्रिम','grain_advance':'धान्य अग्रिम','society':'कर्मचारी सोसायटी','other':'इतर वजाती'};

class LasalgaonApp extends StatelessWidget {
  const LasalgaonApp({super.key});
  static const burgundy = Color(0xFF7D1D2B);
  static const canvas = Color(0xFFF6F5F2);
  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: burgundy, brightness: Brightness.light).copyWith(
      primary: burgundy,
      surface: Colors.white,
      onSurface: const Color(0xFF25242A),
      secondary: const Color(0xFFB9864B),
    );
    return MaterialApp(
      title: 'लासलगाव ग्रामपंचायत वेतन',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: canvas,
        appBarTheme: const AppBarTheme(
          backgroundColor: canvas, foregroundColor: Color(0xFF25242A),
          centerTitle: false, elevation: 0, scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF25242A)),
        ),
        cardTheme: CardThemeData(
          color: Colors.white, elevation: 0, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Color(0xFFEAE7E2))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFFFAF9F7),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E1DB))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE6E1DB))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: burgundy, width: 1.5)),
        ),
        filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        )),
        navigationBarTheme: NavigationBarThemeData(
          height: 72, backgroundColor: Colors.white, indicatorColor: burgundy.withValues(alpha: .10),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(fontSize: 11, fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500)),
        ),
        dividerColor: const Color(0xFFEAE7E2),
      ),
      home: const Gate(),
    );
  }
}
class Gate extends StatefulWidget { const Gate({super.key}); @override State<Gate> createState()=>_GateState(); }
class _GateState extends State<Gate> {
  bool logged = false, obscure = true, busy = false;
  final pass = TextEditingController();
  String error = '';
  @override void dispose() { pass.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    if (logged) return const Home();
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF6F5F2), Color(0xFFEDE6E2)])),
        child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(22), child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(children: [
            Container(width: 88, height: 88, padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: LasalgaonApp.burgundy.withValues(alpha: .10), blurRadius: 28, offset: const Offset(0, 10))]), child: Image.asset('assets/lasalgaon_logo.jpg', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance_rounded, size: 48, color: LasalgaonApp.burgundy))),
            const SizedBox(height: 22),
            const Text('लासलगाव ग्रामपंचायत', textAlign: TextAlign.center, style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, letterSpacing: -.5, color: Color(0xFF29262B))),
            const SizedBox(height: 7),
            const Text('वेतन व्यवस्थापन प्रणाली', style: TextStyle(fontSize: 14, color: Color(0xFF77727A))),
            const SizedBox(height: 28),
            Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('पुन्हा स्वागत आहे', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5), const Text('पुढे जाण्यासाठी तुमचा पासवर्ड टाका.', style: TextStyle(color: Color(0xFF77727A), fontSize: 13)),
              const SizedBox(height: 22),
              TextField(controller: pass, obscureText: obscure, textInputAction: TextInputAction.done, onSubmitted: (_) => login(), decoration: InputDecoration(labelText: 'पासवर्ड', prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
              if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error, style: const TextStyle(color: Color(0xFFB3261E), fontSize: 12))),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : login, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_open_rounded), label: Text(busy ? 'तपासत आहे...' : 'सुरक्षित लॉगिन'))),
            ]))),
            const SizedBox(height: 16),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, size: 15, color: Color(0xFF77727A)), SizedBox(width: 6), Text('तुमचा डेटा या डिव्हाइसवरील स्थानिक डेटाबेसमध्ये', style: TextStyle(fontSize: 11, color: Color(0xFF77727A)))]),
          ]),
        )))),
      ),
    );
  }
  Future<void> login() async {
    if (pass.text.isEmpty) { setState(() => error = 'कृपया पासवर्ड टाका.'); return; }
    setState(() { busy = true; error = ''; });
    try {
      final ok = await PayrollDb.instance.verifyPassword(pass.text);
      if (!mounted) return;
      setState(() { logged = ok; busy = false; if (!ok) error = 'पासवर्ड चुकीचा आहे. पुन्हा प्रयत्न करा.'; });
    } catch (_) {
      if (mounted) setState(() { busy = false; error = 'लॉगिन तपासता आले नाही. कृपया पुन्हा प्रयत्न करा.'; });
    }
  }
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  int month = DateTime.now().month, year = DateTime.now().year;
  String dept = departments.first;
  void refresh() => setState(() {});
  static const _titles = ['डॅशबोर्ड', 'मासिक वेतन', 'कर्मचारी', 'रोजंदार', 'अहवाल', 'सेटिंग्ज'];
  Future<void> _openMore() async {
    final chosen = await showModalBottomSheet<int>(
      context: context, showDragHandle: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetContext) => SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('अधिक पर्याय', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _moreTile(sheetContext, Icons.description_outlined, 'अहवाल आणि निर्यात', 'Excel, PDF आणि बॅकअप', 4),
          _moreTile(sheetContext, Icons.tune_rounded, 'सेटिंग्ज', 'कर, पासवर्ड आणि डेटाबेस', 5),
        ]),
      )),
    );
    if (chosen != null && mounted) setState(() => tab = chosen);
  }
  Widget _moreTile(BuildContext c, IconData icon, String title, String subtitle, int value) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    leading: Container(width: 46, height: 46, decoration: BoxDecoration(color: LasalgaonApp.burgundy.withValues(alpha: .08), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: LasalgaonApp.burgundy)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text(subtitle), trailing: const Icon(Icons.chevron_right),
    onTap: () => Navigator.pop(c, value),
  );
  @override Widget build(BuildContext context) {
    final pages = <Widget>[
      Dashboard(month: month, year: year, onOpen: (i) => setState(() => tab = i)),
      PayrollScreen(month: month, year: year, dept: dept, onDept: (v) => setState(() => dept = v), refresh: refresh),
      EmployeesScreen(refresh: refresh),
      DailyScreen(month: month, year: year, refresh: refresh),
      ReportsScreen(month: month, year: year),
      const SettingsScreen(),
    ];
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final navIndex = tab < 4 ? tab : 4;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: LasalgaonApp.burgundy.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)),
            child: Padding(padding: const EdgeInsets.all(5), child: Image.asset('assets/lasalgaon_logo.jpg', fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: LasalgaonApp.burgundy)))),
          const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('लासलगाव ग्रामपंचायत', maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(_titles[tab], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF77727A))),
          ])),
        ]),
        actions: [
          PopupMenuButton<int>(tooltip: 'वेतन महिना निवडा', icon: const Icon(Icons.calendar_month_rounded), onSelected: (v) => setState(() { month = v; }),
            itemBuilder: (_) => List.generate(12, (i) => PopupMenuItem(value: i + 1, child: Row(children: [if (month == i + 1) const Icon(Icons.check, size: 18, color: LasalgaonApp.burgundy), if (month == i + 1) const SizedBox(width: 8), Text(monthNames[i])]))),),
          PopupMenuButton<int>(tooltip: 'वर्ष निवडा', icon: const Icon(Icons.event_available_rounded), onSelected: (v) => setState(() => year = v),
            itemBuilder: (_) => List.generate(21, (i) => PopupMenuItem(value: 2020 + i, child: Text('${2020 + i}')))),
          const SizedBox(width: 6),
        ],
      ),
      body: Row(children: [
        if (wide) NavigationRail(
          selectedIndex: tab, labelType: NavigationRailLabelType.all,
          backgroundColor: Colors.white,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: const [
            NavigationRailDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: Text('डॅशबोर्ड')),
            NavigationRailDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: Text('वेतन')),
            NavigationRailDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: Text('कर्मचारी')),
            NavigationRailDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: Text('रोजंदार')),
            NavigationRailDestination(icon: Icon(Icons.description_outlined), selectedIcon: Icon(Icons.description), label: Text('अहवाल')),
            NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('सेटिंग्ज')),
          ],
        ),
        if (wide) const VerticalDivider(width: 1),
        Expanded(child: IndexedStack(index: tab, children: pages)),
      ]),
      bottomNavigationBar: wide ? null : NavigationBar(
        selectedIndex: navIndex,
        onDestinationSelected: (v) { if (v == 4) { _openMore(); } else { setState(() => tab = v); } },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), selectedIcon: Icon(Icons.space_dashboard), label: 'होम'),
          NavigationDestination(icon: Icon(Icons.payments_outlined), selectedIcon: Icon(Icons.payments), label: 'वेतन'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'कर्मचारी'),
          NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'रोजंदार'),
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), selectedIcon: Icon(Icons.grid_view_rounded), label: 'अधिक'),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  final int month, year;
  final ValueChanged<int> onOpen;
  const Dashboard({super.key, required this.month, required this.year, required this.onOpen});
  Future<Map<String, Object?>> _load() async {
    final all = await PayrollDb.instance.employees(activeOnly: true);
    final tax = await PayrollDb.instance.taxSettings();
    final days = DateTime(year, month + 1, 0).day;
    final payroll = all.map((e) => calculate(e, tax, days)).toList();
    final daily = await PayrollDb.instance.dailyEmployees(activeOnly: true);
    return {'employees': all, 'payroll': payroll, 'daily': daily};
  }
  @override Widget build(BuildContext context) => FutureBuilder<Map<String, Object?>>(
    future: _load(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('डॅशबोर्ड लोड करता आला नाही.\n${snapshot.error}', textAlign: TextAlign.center)));
      final employees = (snapshot.data!['employees'] as List).cast<Map<String, Object?>>();
      final payroll = (snapshot.data!['payroll'] as List).cast<Map<String, Object?>>();
      final daily = (snapshot.data!['daily'] as List).cast<Map<String, Object?>>();
      final net = payroll.fold<double>(0, (sum, r) => sum + n(r['net']));
      final basic = payroll.fold<double>(0, (sum, r) => sum + n(r['basic']));
      final gross = payroll.fold<double>(0, (sum, r) => sum + n(r['gross']));
      return LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final columns = constraints.maxWidth >= 1100 ? 4 : constraints.maxWidth >= 560 ? 2 : 2;
        return ListView(padding: EdgeInsets.fromLTRB(wide ? 28 : 16, 12, wide ? 28 : 16, 28), children: [
          Container(
            padding: EdgeInsets.all(wide ? 28 : 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7D1D2B), Color(0xFF4E1721)]),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: LasalgaonApp.burgundy.withValues(alpha: .15), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('नमस्कार! 👋', style: TextStyle(color: Colors.white.withValues(alpha: .82), fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('वेतन व्यवस्थापन', style: TextStyle(color: Colors.white, fontSize: wide ? 27 : 23, fontWeight: FontWeight.w800, letterSpacing: -.4)),
                  const SizedBox(height: 6),
                  Text('${monthNames[month - 1]} $year  •  मासिक वेतन सारांश', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12)),
                ])),
                Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: .18))), child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 28)),
              ]),
              const SizedBox(height: 24),
              Text('अंदाजित निव्वळ वेतन', style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13)),
              const SizedBox(height: 4),
              Text(money(net), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -.7)),
              const SizedBox(height: 18),
              Wrap(spacing: 10, runSpacing: 8, children: [
                _heroChip(Icons.people_alt_outlined, '${employees.length} कर्मचारी'),
                _heroChip(Icons.calendar_month_outlined, '$month/$year'),
                _heroChip(Icons.groups_2_outlined, '${daily.length} रोजंदार'),
              ]),
            ]),
          ),
          const SizedBox(height: 24),
          _sectionHeading('या महिन्याचा आढावा', 'वेतनाचा झटपट सारांश'),
          const SizedBox(height: 12),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: wide ? 1.9 : 1.45, children: [
            _metricCard('सक्रिय कर्मचारी', '${employees.length}', Icons.people_alt_outlined, const Color(0xFF476B8A), 'कर्मचारी यादी', () => onOpen(2)),
            _metricCard('मूळ वेतन', money(basic), Icons.payments_outlined, const Color(0xFF7D1D2B), 'मासिक एकूण', () => onOpen(1)),
            _metricCard('एकूण सकल वेतन', money(gross), Icons.account_balance_wallet_outlined, const Color(0xFF8A6B36), 'भत्त्यांसह', () => onOpen(1)),
            _metricCard('रोजंदार कर्मचारी', '${daily.length}', Icons.groups_2_outlined, const Color(0xFF4C7B67), 'दैनिक नोंदी', () => onOpen(3)),
          ]),
          const SizedBox(height: 26),
          _sectionHeading('जलद कृती', 'नेहमीची कामे एका टॅपमध्ये'),
          const SizedBox(height: 12),
          GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: wide ? 3 : 1, crossAxisSpacing: 12, mainAxisSpacing: 10, childAspectRatio: wide ? 1.8 : 3.0, children: [
            _quickAction(Icons.calculate_outlined, 'मासिक वेतन', 'विभागनिहाय वेतन तपासा', () => onOpen(1)),
            _quickAction(Icons.person_add_alt_1_rounded, 'कर्मचारी व्यवस्थापन', 'नवीन नोंद किंवा बदल', () => onOpen(2)),
            _quickAction(Icons.description_outlined, 'अहवाल व निर्यात', 'Excel आणि PDF', () => onOpen(4)),
          ]),
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFFFFF7E9), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF0E0C4))), child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, color: Color(0xFF8A6B36)), SizedBox(width: 12), Expanded(child: Text('महत्त्वाचे: अधिकृत वेतन प्रक्रिया करण्यापूर्वी निवडलेला महिना, कर्मचारी माहिती आणि कपाती तपासा. नियमितपणे डेटाबेस बॅकअप घ्या.', style: TextStyle(height: 1.45, color: Color(0xFF5E4A2B)))),
          ])),
        ]);
      });
    },
  );
  Widget _heroChip(IconData icon, String label) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: .12))), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 15, color: Colors.white), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12))]));
  Widget _sectionHeading(String title, String subtitle) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF29262B))), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF77727A)))]))]);
  Widget _metricCard(String title, String value, IconData icon, Color tint, String footer, VoidCallback onTap) => Material(color: Colors.white, borderRadius: BorderRadius.circular(20), child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFEAE7E2))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: tint.withValues(alpha: .10), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: tint, size: 20)), const Spacer(), Icon(Icons.arrow_outward_rounded, size: 16, color: Colors.grey.shade400)]), const SizedBox(height: 10), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: -.4)), Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF68636B))), Text(footer, style: TextStyle(fontSize: 10, color: tint, fontWeight: FontWeight.w700))]))));
  Widget _quickAction(IconData icon, String title, String subtitle, VoidCallback onTap) => Material(color: Colors.white, borderRadius: BorderRadius.circular(18), child: InkWell(borderRadius: BorderRadius.circular(18), onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFEAE7E2))), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: LasalgaonApp.burgundy.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: LasalgaonApp.burgundy)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: Color(0xFF77727A), fontSize: 11))])), const Icon(Icons.chevron_right_rounded, color: Color(0xFF8D8790))]))));
}

class PayrollScreen extends StatefulWidget {final int month,year;final String dept;final ValueChanged<String> onDept;final VoidCallback refresh;const PayrollScreen({super.key,required this.month,required this.year,required this.dept,required this.onDept,required this.refresh});@override State<PayrollScreen> createState()=>_PayrollScreenState();}
class _PayrollScreenState extends State<PayrollScreen>{Future<List<Map<String,Object?>>> load()async{final all=await PayrollDb.instance.employees(activeOnly:true);final tax=await PayrollDb.instance.taxSettings();final days=DateTime(widget.year,widget.month+1,0).day;return all.where((e)=>e['department']==widget.dept).map((e)=>calculate(e,tax,days)).toList();} @override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:SegmentedButton<String>(segments:const [ButtonSegment(value:'ग्रामनिधी',label:Text('ग्रामनिधी')),ButtonSegment(value:'पाणी पुरवठा',label:Text('पाणी पुरवठा'))],selected:{widget.dept},onSelectionChanged:(v)=>widget.onDept(v.first))),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:load(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;final total=rows.fold<double>(0,(a,r)=>a+n(r['net']));if(rows.isEmpty)return const Center(child:Text('कर्मचारी नाहीत. कर्मचारी विभागातून नोंद जोडा.'));return Column(children:[Card(child:ListTile(title:const Text('एकूण निव्वळ वेतन'),trailing:Text(money(total),style:Theme.of(c).textTheme.titleLarge))),Expanded(child:ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ExpansionTile(title:Text('${i+1}. ${r['name_marathi']??''}'),subtitle:Text('${r['designation']??''}  •  निव्वळ: ${money(r['net'])}'),children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[_line('मूळ वेतन',r['basic']),_line('एकूण वेतन',r['gross']),_line('वसुली',r['recovery_amount']),_line('व्यवसाय कर',r['professional_tax']),_line('एकूण वजाती',r['deductions']),_line('निव्वळ वेतन',r['net']),const SizedBox(height:8),Wrap(spacing:8,children:[FilledButton.icon(onPressed:()=>_edit(c,r),icon:const Icon(Icons.edit),label:const Text('वेतन बदला')),OutlinedButton.icon(onPressed:()=>_editEmployee(c,r),icon:const Icon(Icons.account_balance),label:const Text('बँक तपशील'))])]))]));}))]);}))]);}
Widget _line(String k,Object? v)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(k)),Text(money(v),style:const TextStyle(fontWeight:FontWeight.w600))]));
Future<void> _edit(BuildContext context, Map<String, Object?> row) async {
  final fields = salaryFields.entries.toList();
  final ctrls = {
    for (final e in fields)
      e.key: TextEditingController(text: '${row[e.key] ?? 0}'),
  };
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text('${row['name_marathi']} — वेतन'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: fields.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: ctrls[e.key],
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: e.value),
              ),
            )).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d),
          child: const Text('रद्द'),
        ),
        FilledButton(
          onPressed: () async {
            final patch = <String, Object?>{};
            for (final e in fields) {
              patch[e.key] = double.tryParse(ctrls[e.key]!.text) ?? 0;
            }
            await PayrollDb.instance.saveEmployee({...row, ...patch});
            if (context.mounted) Navigator.pop(d);
          },
          child: const Text('जतन करा'),
        ),
      ],
    ),
  );
}

Future<void> _editEmployee(BuildContext context, Map<String, Object?> row) async {
  final fields = <String, String>{
    'gram_salary_account': 'ग्रामनिधी Salary Account',
    'gram_salary_ifsc': 'ग्रामनिधी Salary IFSC',
    'gram_ppf_account': 'ग्रामनिधी PPF Account',
    'gram_ppf_ifsc': 'ग्रामनिधी PPF IFSC',
    'water_salary_account': 'पाणी पुरवठा Salary Account',
    'water_salary_ifsc': 'पाणी पुरवठा Salary IFSC',
    'water_ppf_account': 'पाणी पुरवठा PPF Account',
    'water_ppf_ifsc': 'पाणी पुरवठा PPF IFSC',
  };
  final cs = {
    for (final k in fields.keys)
      k: TextEditingController(text: '${row[k] ?? ''}'),
  };
  await showDialog<void>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('बँक खाते तपशील'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: fields.entries.map((e) => TextField(
              controller: cs[e.key],
              decoration: InputDecoration(labelText: e.value),
            )).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d),
          child: const Text('रद्द'),
        ),
        FilledButton(
          onPressed: () async {
            await PayrollDb.instance.saveEmployee({
              ...row,
              for (final k in fields.keys) k: cs[k]!.text,
            });
            if (context.mounted) Navigator.pop(d);
          },
          child: const Text('जतन करा'),
        ),
      ],
    ),
  );
}
}

class EmployeesScreen extends StatefulWidget {final VoidCallback refresh;const EmployeesScreen({super.key,required this.refresh});@override State<EmployeesScreen> createState()=>_EmployeesScreenState();}
class _EmployeesScreenState extends State<EmployeesScreen>{String dept=departments.first;@override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:DropdownButtonFormField(value:dept,items:departments.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setState(()=>dept=v!),decoration:const InputDecoration(labelText:'विभाग'))),const SizedBox(width:10),FilledButton.icon(onPressed:()=>_form(c),icon:const Icon(Icons.person_add),label:const Text('नवीन'))])),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:PayrollDb.instance.employees(),builder:(c,s){final rows=(s.data??[]).where((r)=>r['department']==dept).toList();return ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ListTile(title:Text('${r['name_marathi']??''}'),subtitle:Text('${r['designation']??''} • ${r['gender']??'unspecified'} • ${r['is_active']==1?'सक्रिय':'निष्क्रिय'}'),onTap:()=>_form(c,existing:r),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='disable')await PayrollDb.instance.deactivateEmployee(r['id'] as int);else await _form(c,existing:r);setState((){});},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('संपादित करा')),PopupMenuItem(value:'disable',child:Text('निष्क्रिय करा'))])));});}))]);Future<void> _form(BuildContext c,{Map<String,Object?>? existing})async{final fields=['name_marathi','name_english','designation','pay_scale','basic','leave_salary','substitution_salary','da','gender','dob','account_number','ifsc','bank','branch'];final labels=['नाव (मराठी)','नाव (English)','पद','वेतनश्रेणी','मूळ वेतन','रजा वेतन','स्थानार्पण वेतन','महागाई भत्ता','लिंग (male/female/unspecified)','जन्मतारीख (YYYY-MM-DD)','बँक खाते','IFSC','बँक','शाखा'];final cs={for(final k in fields)k:TextEditingController(text:'${existing?[k]??(k=='gender'?'unspecified':'')}')};String selected=existing?['department'] as String? ?? dept;await showDialog(context:c,builder:(d)=>AlertDialog(title:Text(existing==null?'कर्मचारी जोडा':'कर्मचारी संपादित करा'),content:SizedBox(width:460,child:SingleChildScrollView(child:Column(children:[DropdownButtonFormField(value:selected,items:departments.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>selected=v!,decoration:const InputDecoration(labelText:'विभाग')),...List.generate(fields.length,(i)=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:cs[fields[i]],keyboardType:['basic','leave_salary','substitution_salary','da'].contains(fields[i])?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:labels[i]))))]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{final v=<String,Object?>{for(final k in fields)k:cs[k]!.text};for(final k in ['basic','leave_salary','substitution_salary','da'])v[k]=double.tryParse('${v[k]}')??0;v.addAll({'department':selected,'is_active':1,'living_enabled':1,'gp_enabled':1,'sort_order':0});if(existing!=null)v['id']=existing['id'];await PayrollDb.instance.saveEmployee(v);if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}
}

class DailyScreen extends StatefulWidget{final int month,year;final VoidCallback refresh;const DailyScreen({super.key,required this.month,required this.year,required this.refresh});@override State<DailyScreen> createState()=>_DailyScreenState();}
class _DailyScreenState extends State<DailyScreen>{@override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[const Expanded(child:Text('रोजंदार वेतन',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold))),FilledButton.icon(onPressed:()=>_add(c),icon:const Icon(Icons.add),label:const Text('कर्मचारी जोडा'))])),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:PayrollDb.instance.dailyRows(widget.month,widget.year),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;return ListView(children:[Card(child:ListTile(title:Text('महिन्याचे दिवस: ${DateTime(widget.year,widget.month+1,0).day}'),subtitle:Text('${widget.month}/${widget.year}'))),...rows.map((r)=>Card(child:ExpansionTile(title:Text('${r['name']}'),subtitle:Text('${r['employee_type']} • निव्वळ ${money(r['net'])}'),children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[_line('एकूण वेतन',r['gross']),_line('वसुली',r['recovery']),_line('निव्वळ वेतन',r['net']),Row(children:[Expanded(child:TextButton(onPressed:()=>_cell(c,r,'daily_rate','दैनिक दर'),child:Text('दर: ${money(r['daily_rate'])}'))),Expanded(child:TextButton(onPressed:()=>_cell(c,r,'absent_days','अनुपस्थित दिवस'),child:Text('गैरहजर: ${r['absent_days']}')))])]))]))]) ;}))]);Future<void> _cell(BuildContext c,Map<String,Object?> r,String field,String label)async{final ctl=TextEditingController(text:'${r[field]}');await showDialog(context:c,builder:(d)=>AlertDialog(title:Text(label),content:TextField(controller:ctl,keyboardType:TextInputType.number),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{final v=double.tryParse(ctl.text)??0;await PayrollDb.instance.saveDailyCell(r['id'] as int,widget.month,widget.year,field,v);if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}Future<void> _add(BuildContext c)async{final name=TextEditingController(),acc=TextEditingController(),ifsc=TextEditingController(),bank=TextEditingController(),branch=TextEditingController();String type='इतर';await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('रोजंदार कर्मचारी'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[for(final e in {'नाव':name,'खाते क्रमांक':acc,'IFSC':ifsc,'बँक':bank,'शाखा':branch}.entries)Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:e.value,decoration:InputDecoration(labelText:e.key))),DropdownButtonFormField(value:type,items:['शौचालय कर्मचारी','वाहनचालक','इतर'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>type=v!)]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{if(name.text.trim().isEmpty||acc.text.trim().isEmpty||ifsc.text.length!=11)return;await PayrollDb.instance.saveDailyEmployee({'name':name.text.trim(),'account_number':acc.text.trim(),'ifsc':ifsc.text.toUpperCase(),'bank_name':bank.text,'branch':branch.text,'employee_type':type,'is_active':1});if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}}

class ReportsScreen extends StatelessWidget{final int month,year;const ReportsScreen({super.key,required this.month,required this.year});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Text('अहवाल आणि निर्यात',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.table_chart),title:const Text('Excel वेतन अहवाल'),subtitle:const Text('निवडलेल्या महिन्याची कर्मचारी व निव्वळ वेतन यादी'),trailing:const Icon(Icons.download),onTap:()=>_excel(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.picture_as_pdf),title:const Text('PDF वेतन सारांश'),subtitle:const Text('प्रिंट किंवा PDF म्हणून जतन करा'),trailing:const Icon(Icons.print),onTap:()=>_pdf(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.email_outlined),title:const Text('ईमेलने वेतन Excel पाठवा'),subtitle:Text('${monthNames[month-1]} $year चा Excel अहवाल संलग्न होईल'),trailing:const Icon(Icons.send_rounded),onTap:()=>_sendSalaryEmail(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.backup),title:const Text('डेटाबेस बॅकअप'),subtitle:const Text('स्थानिक payroll.db फाईल शेअर करा'),onTap:()=>_backup(c))),const Padding(padding:EdgeInsets.all(12),child:Text('ईमेल पाठवण्यासाठी आधी सेटिंग्जमध्ये Gmail From, To आणि App Password जतन करा. SMTP सर्व्हरने स्वीकारल्यावरच यशाचा संदेश दिसेल. मूळ डेस्कटॉप अॅपमधील सहा पूर्ण स्वरूपित शीट्स व प्रिंट रजिस्टर अजून parity तपासणीमध्ये आहेत.'))]);
Future<File> _createSalaryWorkbookFile(int m,int y)async{final all=await PayrollDb.instance.employees(activeOnly:true);final tax=await PayrollDb.instance.taxSettings();final rows=all.map((r)=>calculate(r,tax,DateTime(y,m+1,0).day)).toList();final excel=Excel.createExcel();final sheet=excel['वेतन'];sheet.appendRow([
  const TextCellValue('अ.नं.'), const TextCellValue('नाव'),
  const TextCellValue('पद'), const TextCellValue('विभाग'),
  const TextCellValue('मूळ वेतन'), const TextCellValue('एकूण वेतन'),
  const TextCellValue('वजाती'), const TextCellValue('निव्वळ वेतन'),
]);for(var i=0;i<rows.length;i++){final r=rows[i];sheet.appendRow([IntCellValue(i+1),TextCellValue('${r['name_marathi']??''}'),TextCellValue('${r['designation']??''}'),TextCellValue('${r['department']??''}'),DoubleCellValue(n(r['basic'])),DoubleCellValue(n(r['gross'])),DoubleCellValue(n(r['deductions'])),DoubleCellValue(n(r['net']))]);}final bytes=excel.encode();if(bytes==null)throw StateError('Excel workbook तयार करता आला नाही.');final dir=await getTemporaryDirectory();final file=File('${dir.path}/Lasalgaon_Grampanchayat_Salary_${m}_$y.xlsx');await file.writeAsBytes(bytes,flush:true);return file;}
Future<void> _excel(BuildContext c,int m,int y)async{try{final file=await _createSalaryWorkbookFile(m,y);await Share.shareXFiles([XFile(file.path)],text:'लासलगाव ग्रामपंचायत वेतन $m/$y');}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('Excel तयार करता आले नाही: $e')));}}
Future<void> _sendSalaryEmail(BuildContext c,int m,int y)async{final prefs=await SharedPreferences.getInstance();final from=(prefs.getString('smtp_from_email')??'').trim();final to=(prefs.getString('smtp_to_email')??'').trim();const secure=FlutterSecureStorage();final password=(await secure.read(key:'smtp_app_password')??'').replaceAll(' ','').trim();if(from.isEmpty||to.isEmpty||password.isEmpty){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('ईमेल सेटिंग अपूर्ण आहे. सेटिंग्जमध्ये From, To आणि Gmail App Password जतन करा.')));return;}if(!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(from)||!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(to)){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('From आणि To ईमेल पत्ते तपासा.')));return;}showDialog<void>(context:c,barrierDismissible:false,builder:(_)=>const AlertDialog(content:Row(children:[CircularProgressIndicator(),SizedBox(width:16),Expanded(child:Text('वेतन Excel तयार करून ईमेल पाठवत आहे...'))])));try{final file=await _createSalaryWorkbookFile(m,y);final server=SmtpServer('smtp.gmail.com',port:587,username:from,password:password,ssl:false,allowInsecure:false);final message=Message()..from=Address(from,'Lasalgaon Gram Panchayat')..recipients.add(to)..subject='Lasalgaon Gram Panchayat Salary ${monthNames[m-1]} $y'..text='नमस्कार,\n\nलासलगाव ग्रामपंचायतीच्या ${monthNames[m-1]} $y महिन्याच्या वेतनाची Excel नोंद संलग्न केली आहे.\n\nलासलगाव ग्रामपंचायत'..attachments.add(FileAttachment(file));final refused=await send(message,server);if(refused.isNotEmpty)throw StateError('SMTP ने recipient स्वीकारला नाही: ${refused.join(', ')}');if(c.mounted)Navigator.of(c,rootNavigator:true).pop();if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('ईमेल SMTP सर्व्हरने स्वीकारला: $to')));}catch(e){if(c.mounted)Navigator.of(c,rootNavigator:true).pop();if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('ईमेल पाठवता आला नाही: ${_emailError(e)}'),duration:const Duration(seconds:8)));}}
String _emailError(Object e){final s=e.toString();if(s.contains('535')||s.toLowerCase().contains('authentication'))return 'Gmail authentication अयशस्वी. Gmail मध्ये 2-Step Verification सुरू करून नवीन 16-अक्षरी App Password वापरा. ($s)';if(s.contains('SocketException')||s.contains('Connection timed out'))return 'नेटवर्क किंवा SMTP कनेक्शन अयशस्वी. इंटरनेट तपासा आणि पुन्हा प्रयत्न करा. ($s)';return s;}
Future<void> _pdf(BuildContext c,int m,int y)async{final all=await PayrollDb.instance.employees(activeOnly:true);final tax=await PayrollDb.instance.taxSettings();final rows=all.map((r)=>calculate(r,tax,DateTime(y,m+1,0).day)).toList();final doc=pw.Document();doc.addPage(pw.MultiPage(build:(ctx)=>[pw.Header(level:0,child:pw.Text('Lasalgaon Gram Panchayat Payroll — $m/$y')),pw.Table.fromTextArray(headers:['No.','Name','Designation','Basic','Gross','Deductions','Net'],data:[for(var i=0;i<rows.length;i++)['${i+1}','${rows[i]['name_marathi']??''}','${rows[i]['designation']??''}','${n(rows[i]['basic']).toStringAsFixed(0)}','${n(rows[i]['gross']).toStringAsFixed(0)}','${n(rows[i]['deductions']).toStringAsFixed(0)}','${n(rows[i]['net']).toStringAsFixed(0)}']]) ]));await Printing.layoutPdf(onLayout:(_)=>doc.save());}
Future<void> _backup(BuildContext c)async{final dir=await getApplicationDocumentsDirectory();final file=File('${dir.path}/payroll.db');if(await file.exists())await Share.shareXFiles([XFile(file.path)],text:'Payroll database backup');else if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('डेटाबेस अद्याप तयार नाही')));}

class SettingsScreen extends StatefulWidget{const SettingsScreen({super.key});@override State<SettingsScreen> createState()=>_SettingsScreenState();}
class _SettingsScreenState extends State<SettingsScreen>{@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Text('सेटिंग्ज',style:Theme.of(c).textTheme.headlineSmall),Card(child:ListTile(leading:const Icon(Icons.email_outlined),title:const Text('ईमेल / SMTP सेटिंग'),subtitle:const Text('Gmail App Password आणि प्राप्तकर्ता जतन करा'),trailing:const Icon(Icons.chevron_right),onTap:()=>_emailSettings(c))),Card(child:ListTile(leading:const Icon(Icons.receipt_long),title:const Text('व्यवसाय कर सेटिंग'),subtitle:const Text('मर्यादा आणि कर रक्कम'),onTap:()=>_tax(c))),Card(child:ListTile(leading:const Icon(Icons.lock_reset),title:const Text('पासवर्ड बदला'),onTap:()=>_password(c))),Card(child:ListTile(leading:const Icon(Icons.event_available),title:const Text('पदानुसार निवृत्ती वय'),subtitle:const Text('डीफॉल्ट निवृत्ती वय 60 वर्षे'),onTap:()=>_retirement(c))),Card(child:ListTile(leading:const Icon(Icons.upload_file),title:const Text('जुना डेटाबेस आयात'),subtitle:const Text('जुन्या payroll.db फाईलसाठी'),onTap:()=>_importDb(c))),const Padding(padding:EdgeInsets.all(12),child:Text('डेटा या Android डिव्हाइसवर स्थानिक SQLite डेटाबेसमध्ये साठवला जातो. भविष्यात multi-user वापरासाठी API/backend migration आवश्यक असेल.'))]);}
Future<void> _emailSettings(BuildContext c) async {
  final prefs = await SharedPreferences.getInstance();
  const secure = FlutterSecureStorage();
  final from = TextEditingController(text: prefs.getString('smtp_from_email') ?? '');
  final to = TextEditingController(text: prefs.getString('smtp_to_email') ?? '');
  final pass = TextEditingController();
  var showPassword = false;
  final configured = (await secure.read(key: 'smtp_app_password'))?.isNotEmpty ?? false;
  if (!c.mounted) return;
  await showDialog<void>(
    context: c,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialog) => AlertDialog(
        title: const Text('ईमेल / SMTP सेटिंग'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Gmail SMTP', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: from,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'From — Gmail पत्ता',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: to,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'To — अहवाल मिळणारा पत्ता',
                    prefixIcon: Icon(Icons.mark_email_read_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: pass,
                  obscureText: !showPassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: configured ? 'नवीन App Password (बदलायचा असल्यास)' : 'Gmail App Password',
                    helperText: configured
                        ? 'रिक्त ठेवल्यास आधीचा password कायम राहील.'
                        : '16-अक्षरी Gmail App Password टाका.',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(showPassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDialog(() => showPassword = !showPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Google Account मध्ये 2-Step Verification सुरू करून स्वतंत्र App Password तयार करा. नियमित Gmail खाते password येथे टाकू नका.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('रद्द')),
          FilledButton.icon(
            onPressed: () async {
              final f = from.text.trim();
              final t = to.text.trim();
              final pw = pass.text.replaceAll(' ', '').trim();
              final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
              if (!valid.hasMatch(f) || !valid.hasMatch(t)) {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('योग्य From आणि To ईमेल पत्ते टाका.')),
                );
                return;
              }
              if (pw.isNotEmpty && pw.length < 16) {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('Gmail App Password साधारण 16 अक्षरी असतो. योग्य App Password टाका.')),
                );
                return;
              }
              if (pw.isEmpty && !configured) {
                ScaffoldMessenger.of(c).showSnackBar(
                  const SnackBar(content: Text('पहिल्यांदा App Password आवश्यक आहे.')),
                );
                return;
              }
              await prefs.setString('smtp_from_email', f);
              await prefs.setString('smtp_to_email', t);
              if (pw.isNotEmpty) await secure.write(key: 'smtp_app_password', value: pw);
              if (!c.mounted) return;
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(c).showSnackBar(
                const SnackBar(content: Text('ईमेल सेटिंग सुरक्षितपणे जतन झाली. आता अहवालातून ईमेल पाठवा.')),
              );
            },
            icon: const Icon(Icons.save_outlined),
            label: const Text('जतन करा'),
          ),
        ],
      ),
    ),
  );
}
Future<void> _tax(BuildContext c)async{final tax=await PayrollDb.instance.taxSettings();final keys=['threshold','below_amount','above_amount','women_amount'];final labels=['मूळ वेतन मर्यादा','मर्यादेखाली कर','मर्यादेवर/वर कर','महिला कर्मचारी कर'];final cs={for(final k in keys)k:TextEditingController(text:'${tax[k]}')};if(!c.mounted)return;await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('व्यवसाय कर सेटिंग'),content:Column(mainAxisSize:MainAxisSize.min,children:[for(var i=0;i<keys.length;i++)TextField(controller:cs[keys[i]],keyboardType:TextInputType.number,decoration:InputDecoration(labelText:labels[i]))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{await PayrollDb.instance.saveTax({for(final k in keys)k:double.tryParse(cs[k]!.text)??0});if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}
Future<void> _password(BuildContext c)async{final old=TextEditingController(),next=TextEditingController(),confirm=TextEditingController();await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('पासवर्ड बदला'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:old,obscureText:true,decoration:const InputDecoration(labelText:'सध्याचा पासवर्ड')),TextField(controller:next,obscureText:true,decoration:const InputDecoration(labelText:'नवीन पासवर्ड')),TextField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'पुन्हा पासवर्ड'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{if(!await PayrollDb.instance.verifyPassword(old.text)||next.text.length<8||next.text!=confirm.text){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('सध्याचा पासवर्ड तपासा. नवीन पासवर्ड किमान 8 अक्षरांचा आणि जुळणारा असावा.')));return;}await PayrollDb.instance.savePassword(next.text);if(c.mounted)Navigator.pop(d);},child:const Text('बदला'))]));}
Future<void> _retirement(BuildContext c)async{final rows=await PayrollDb.instance.employees(activeOnly:true);final names=rows.map((r)=>'${r['designation']??''}').where((s)=>s.isNotEmpty).toSet().toList();for(final name in names){final existing=await (await PayrollDb.instance.db).query('retirement_age_settings',where:'designation=?',whereArgs:[name]);final ctl=TextEditingController(text:existing.isEmpty?'60':'${existing.first['retirement_age']}');if(!c.mounted)return;await showDialog(context:c,builder:(d)=>AlertDialog(title:Text('$name — निवृत्ती वय'),content:TextField(controller:ctl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'वय (वर्षे)')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('बंद')),FilledButton(onPressed:()async{await (await PayrollDb.instance.db).insert('retirement_age_settings',{'designation':name,'retirement_age':int.tryParse(ctl.text)??60},conflictAlgorithm:ConflictAlgorithm.replace);if(c.mounted)Navigator.pop(d);},child:const Text('जतन करा'))]));}}
Future<void> _importDb(BuildContext c)async{final pick=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['db','sqlite','sqlite3'],withData:true);if(pick==null||pick.files.single.bytes==null)return;final bytes=pick.files.single.bytes!;if(bytes.length<16||String.fromCharCodes(bytes.take(15))!='SQLite format 3') {if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('ही वैध SQLite डेटाबेस फाईल नाही.')));return;}if(!c.mounted)return; final confirm=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('डेटाबेस आयात करा?'),content:const Text('सध्याच्या डेटाबेसचा .backup तयार होईल आणि निवडलेली फाईल सध्याचा डेटा बदलेल. पुढे सुरू ठेवायचे?'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('रद्द')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('आयात करा'))])); if(confirm!=true)return; try{await PayrollDb.instance.replaceDatabase(bytes);if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('डेटाबेस आयात झाला. कृपया अॅप पुन्हा उघडा.')));}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('आयात अयशस्वी: $e')));}}
