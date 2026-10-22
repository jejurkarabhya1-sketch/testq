import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

const employeeTextFields = <String>{
  'name_marathi', 'name_english', 'designation', 'department', 'gender', 'dob',
  'pay_scale', 'account_number', 'ifsc', 'bank', 'branch', 'gram_salary_account',
  'gram_salary_ifsc', 'gram_ppf_account', 'gram_ppf_ifsc', 'water_salary_account',
  'water_salary_ifsc', 'water_ppf_account', 'water_ppf_ifsc'
};
const employeeNumberFields = <String>{
  'basic', 'leave_salary', 'substitution_salary', 'da', 'future_payable',
  'recovery', 'recovery_days', 'loan', 'insurance', 'festival_advance',
  'grain_advance', 'society', 'other', 'sort_order', 'living_enabled', 'gp_enabled',
  'is_active'
};
const bankFields = <String>[
  'gram_salary_account', 'gram_salary_ifsc', 'gram_ppf_account', 'gram_ppf_ifsc',
  'water_salary_account', 'water_salary_ifsc', 'water_ppf_account', 'water_ppf_ifsc'
];

class PayrollDb {
  PayrollDb._();
  static final PayrollDb instance = PayrollDb._();
  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openDatabase(
      p.join(dir.path, 'payroll.db'),
      version: 5,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async => _createSchema(d),
      onUpgrade: (d, old, newVersion) async {
        await _ensureSchema(d);
        await _ensureColumns(d);
      },
    );
  }

  Future<void> _createSchema(DatabaseExecutor d) async {
    await d.execute('''CREATE TABLE IF NOT EXISTS employees(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name_marathi TEXT, name_english TEXT,
      designation TEXT, department TEXT, gender TEXT NOT NULL DEFAULT 'unspecified', dob TEXT,
      pay_scale TEXT, basic REAL DEFAULT 0, leave_salary REAL DEFAULT 0,
      substitution_salary REAL DEFAULT 0, living_enabled INTEGER DEFAULT 1, da REAL DEFAULT 0,
      gp_enabled INTEGER DEFAULT 1, future_payable REAL DEFAULT 0, recovery REAL DEFAULT 0,
      recovery_days REAL DEFAULT 0, pf_employee REAL DEFAULT 0, pf_employer REAL DEFAULT 0,
      loan REAL DEFAULT 0, professional_tax REAL DEFAULT 0, insurance REAL DEFAULT 0,
      festival_advance REAL DEFAULT 0, grain_advance REAL DEFAULT 0, society REAL DEFAULT 0,
      other REAL DEFAULT 0, account_number TEXT, ifsc TEXT, bank TEXT, branch TEXT,
      sort_order INTEGER DEFAULT 0, is_active INTEGER DEFAULT 1,
      gram_salary_account TEXT DEFAULT '', gram_salary_ifsc TEXT DEFAULT '',
      gram_ppf_account TEXT DEFAULT '', gram_ppf_ifsc TEXT DEFAULT '',
      water_salary_account TEXT DEFAULT '', water_salary_ifsc TEXT DEFAULT '',
      water_ppf_account TEXT DEFAULT '', water_ppf_ifsc TEXT DEFAULT '')''');
    await d.execute('''CREATE TABLE IF NOT EXISTS payroll_periods(
      id INTEGER PRIMARY KEY AUTOINCREMENT, month INTEGER NOT NULL, year INTEGER NOT NULL,
      created TEXT DEFAULT CURRENT_TIMESTAMP, UNIQUE(month,year))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS payroll_entries(
      id INTEGER PRIMARY KEY AUTOINCREMENT, period_id INTEGER NOT NULL, employee_id INTEGER NOT NULL,
      snapshot TEXT NOT NULL, UNIQUE(period_id,employee_id),
      FOREIGN KEY(period_id) REFERENCES payroll_periods(id) ON DELETE CASCADE)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS daily_wage_employees(
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, account_number TEXT NOT NULL,
      ifsc TEXT NOT NULL, bank_name TEXT DEFAULT '', branch TEXT DEFAULT '',
      employee_type TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1, created TEXT DEFAULT CURRENT_TIMESTAMP)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS daily_wage_payroll(
      id INTEGER PRIMARY KEY AUTOINCREMENT, employee_id INTEGER NOT NULL, month INTEGER NOT NULL,
      year INTEGER NOT NULL, daily_rate REAL NOT NULL DEFAULT 300, absent_days REAL NOT NULL DEFAULT 0,
      UNIQUE(employee_id,month,year), FOREIGN KEY(employee_id) REFERENCES daily_wage_employees(id))''');
    await d.execute('''CREATE TABLE IF NOT EXISTS professional_tax_settings(
      id INTEGER PRIMARY KEY CHECK(id=1), threshold REAL NOT NULL, below_amount REAL NOT NULL,
      above_amount REAL NOT NULL, women_amount REAL NOT NULL)''');
    await d.execute('''CREATE TABLE IF NOT EXISTS retirement_age_settings(
      designation TEXT PRIMARY KEY COLLATE NOCASE, retirement_age INTEGER NOT NULL)''');
    await d.execute('CREATE TABLE IF NOT EXISTS app_settings(key TEXT PRIMARY KEY,value TEXT)');
    await d.execute('''CREATE TABLE IF NOT EXISTS email_settings(
      id INTEGER PRIMARY KEY CHECK(id=1), from_email TEXT NOT NULL DEFAULT '',
      to_email TEXT NOT NULL DEFAULT '', app_password TEXT NOT NULL DEFAULT '',
      signature_role TEXT NOT NULL DEFAULT 'prashasak')''');
    await d.insert('professional_tax_settings', {
      'id': 1, 'threshold': 10000, 'below_amount': 175, 'above_amount': 200, 'women_amount': 0,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    final pass = await d.query('app_settings', where: 'key=?', whereArgs: ['password_hash']);
    if (pass.isEmpty) await _setPassword(d, 'admin');
  }

  Future<void> _ensureSchema(DatabaseExecutor d) async {
    await _createSchema(d);
  }

  Future<void> _ensureColumns(DatabaseExecutor d) async {
    final columns = await d.rawQuery('PRAGMA table_info(employees)');
    final existing = columns.map((r) => '${r['name']}').toSet();
    const additions = <String, String>{
      'gender': "TEXT NOT NULL DEFAULT 'unspecified'", 'dob': 'TEXT',
      'recovery_days': 'REAL DEFAULT 0', 'gram_salary_account': "TEXT DEFAULT ''",
      'gram_salary_ifsc': "TEXT DEFAULT ''", 'gram_ppf_account': "TEXT DEFAULT ''",
      'gram_ppf_ifsc': "TEXT DEFAULT ''", 'water_salary_account': "TEXT DEFAULT ''",
      'water_salary_ifsc': "TEXT DEFAULT ''", 'water_ppf_account': "TEXT DEFAULT ''",
      'water_ppf_ifsc': "TEXT DEFAULT ''", 'pf_employee': 'REAL DEFAULT 0',
      'pf_employer': 'REAL DEFAULT 0', 'sort_order': 'INTEGER DEFAULT 0',
      'is_active': 'INTEGER DEFAULT 1', 'living_enabled': 'INTEGER DEFAULT 1',
      'gp_enabled': 'INTEGER DEFAULT 1', 'name_english': 'TEXT', 'pay_scale': 'TEXT',
    };
    for (final e in additions.entries) {
      if (!existing.contains(e.key)) await d.execute('ALTER TABLE employees ADD COLUMN ${e.key} ${e.value}');
    }
    await d.execute('CREATE TABLE IF NOT EXISTS app_settings(key TEXT PRIMARY KEY,value TEXT)');
    await d.execute('CREATE TABLE IF NOT EXISTS retirement_age_settings(designation TEXT PRIMARY KEY COLLATE NOCASE,retirement_age INTEGER NOT NULL)');
    await d.execute('''CREATE TABLE IF NOT EXISTS email_settings(id INTEGER PRIMARY KEY CHECK(id=1),from_email TEXT NOT NULL DEFAULT '',to_email TEXT NOT NULL DEFAULT '',app_password TEXT NOT NULL DEFAULT '',signature_role TEXT NOT NULL DEFAULT 'prashasak')''');
    await d.insert('professional_tax_settings', {'id':1,'threshold':10000,'below_amount':175,'above_amount':200,'women_amount':0}, conflictAlgorithm: ConflictAlgorithm.ignore);
    final saved = await d.query('app_settings', where: 'key=?', whereArgs: ['password_hash']);
    if (saved.isEmpty) await _setPassword(d, 'admin');
  }

  Future<void> _setPassword(DatabaseExecutor d, String password) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    await d.insert('app_settings', {
      'key': 'password_hash',
      'value': '${base64Encode(salt)}:${sha256.convert([...salt, ...utf8.encode(password)])}',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, Object?>>> employees({bool activeOnly = false}) async =>
      (await db).query('employees', where: activeOnly ? 'is_active=1' : null, orderBy: "CASE department WHEN 'ग्रामनिधी' THEN 0 ELSE 1 END,sort_order,id");

  Future<int> saveEmployee(Map<String, Object?> values) async {
    final d = await db;
    final clean = <String, Object?>{};
    for (final e in values.entries) {
      if (employeeTextFields.contains(e.key) || employeeNumberFields.contains(e.key) ||
          e.key == 'pf_employee' || e.key == 'pf_employer' || e.key == 'professional_tax' ||
          e.key == 'insurance' || e.key == 'festival_advance' || e.key == 'grain_advance' ||
          e.key == 'society' || e.key == 'other' || e.key == 'loan' || e.key == 'recovery' ||
          e.key == 'future_payable') clean[e.key] = e.value;
    }
    final id = values['id'];
    if (id == null) return d.insert('employees', clean);
    await d.update('employees', clean, where: 'id=?', whereArgs: [id]);
    return id as int;
  }

  Future<void> deactivateEmployee(int id) async {
    final d = await db;
    await d.update('employees', {'is_active': 0}, where: 'id=?', whereArgs: [id]);
    final now = DateTime.now();
    final periods = await d.query('payroll_periods', where: 'month=? AND year=?', whereArgs: [now.month, now.year]);
    if (periods.isEmpty) return;
    final entries = await d.query('payroll_entries', where: 'period_id=? AND employee_id=?', whereArgs: [periods.first['id'], id]);
    if (entries.isEmpty) return;
    final snapshot = Map<String, Object?>.from(jsonDecode('${entries.first['snapshot']}') as Map);
    snapshot['is_active'] = 0;
    await d.update('payroll_entries', {'snapshot': jsonEncode(snapshot)}, where: 'period_id=? AND employee_id=?', whereArgs: [periods.first['id'], id]);
  }
  Future<Map<String, Object?>> taxSettings() async => (await db).query('professional_tax_settings', limit: 1).then((r) => r.first);
  Future<void> saveTax(Map<String, Object?> v) async => (await db).update('professional_tax_settings', v, where: 'id=1');

  Future<List<Map<String, Object?>>> periodRows(int month, int year, {String? department, bool activeOnly = true}) async {
    _validatePeriod(month, year);
    final d = await db;
    await d.insert('payroll_periods', {'month': month, 'year': year}, conflictAlgorithm: ConflictAlgorithm.ignore);
    final period = (await d.query('payroll_periods', where: 'month=? AND year=?', whereArgs: [month, year])).first;
    final pid = period['id'];
    final savedRows = await d.query('payroll_entries', where: 'period_id=?', whereArgs: [pid]);
    final saved = <int, Map<String, Object?>>{};
    for (final row in savedRows) {
      final snapshot = Map<String, Object?>.from(jsonDecode('${row['snapshot']}') as Map);
      saved[(row['employee_id'] as num).toInt()] = snapshot;
    }
    final current = await employees();
    for (final e in current) {
      final id = (e['id'] as num).toInt();
      if (e['is_active'] == 1 && !saved.containsKey(id)) {
        final snapshot = Map<String, Object?>.from(e);
        saved[id] = snapshot;
        await d.insert('payroll_entries', {'period_id': pid, 'employee_id': id, 'snapshot': jsonEncode(snapshot)});
      }
    }
    final tax = await taxSettings();
    final days = DateTime(year, month + 1, 0).day;
    final rows = <Map<String, Object?>>[];
    for (final entry in saved.entries) {
      final row = entry.value;
      if (activeOnly && (row['is_active'] ?? 1) != 1) continue;
      if (department != null && row['department'] != department) continue;
      // Keep salary inputs frozen per period; bank/demographic details remain current for payment.
      final latest = current.where((e) => e['id'] == entry.key).firstOrNull;
      if (latest != null) {
        for (final key in [...bankFields, 'gender', 'dob', 'name_english']) {
          row[key] = latest[key];
        }
      }
      rows.add(calculate(row, tax, days));
    }
    rows.sort((a, b) {
      final dpt = ('${a['department']}' == 'पाणी पुरवठा' ? 1 : 0).compareTo('${b['department']}' == 'पाणी पुरवठा' ? 1 : 0);
      return dpt != 0 ? dpt : n(a['sort_order']).compareTo(n(b['sort_order']));
    });
    return rows;
  }

  Future<Map<String, Object?>> savePeriodCell(int id, String field, Object? value, int month, int year) async {
    if (!employeeTextFields.contains(field) && !employeeNumberFields.contains(field) &&
        !{'recovery','loan','insurance','festival_advance','grain_advance','society','other','future_payable'}.contains(field)) {
      throw ArgumentError('This field cannot be edited in a salary period.');
    }
    final d = await db;
    final rows = await periodRows(month, year, activeOnly: false);
    final row = rows.where((r) => r['id'] == id).firstOrNull;
    if (row == null) throw StateError('Employee is not in this salary period.');
    if (value is num && !value.isFinite) throw ArgumentError('Enter a valid number.');
    row[field] = value;
    if (field == 'basic') {
      row['pf_employee'] = roundHalfUp(n(value) * .0833);
      row['pf_employer'] = roundHalfUp(n(value) * .0833);
    }
    final updated = calculate(row, await taxSettings(), DateTime(year, month + 1, 0).day);
    final period = (await d.query('payroll_periods', where: 'month=? AND year=?', whereArgs: [month, year])).first;
    await d.update('payroll_entries', {'snapshot': jsonEncode(updated)}, where: 'period_id=? AND employee_id=?', whereArgs: [period['id'], id]);
    return updated;
  }

  Future<List<Map<String, Object?>>> dailyEmployees({bool activeOnly = false}) async => (await db).query('daily_wage_employees', where: activeOnly ? 'is_active=1' : null, orderBy: 'id');
  Future<int> saveDailyEmployee(Map<String, Object?> v) async => (await db).insert('daily_wage_employees', v);
  Future<void> deactivateDaily(int id) async => (await db).update('daily_wage_employees', {'is_active': 0}, where: 'id=?', whereArgs: [id]);

  Future<List<Map<String, Object?>>> dailyRows(int month, int year) async {
    _validatePeriod(month, year);
    final d = await db;
    final people = await dailyEmployees(activeOnly: true);
    final days = DateTime(year, month + 1, 0).day;
    final out = <Map<String, Object?>>[];
    for (final e in people) {
      await d.insert('daily_wage_payroll', {'employee_id': e['id'], 'month': month, 'year': year, 'daily_rate': 300, 'absent_days': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
      final pay = (await d.query('daily_wage_payroll', where: 'employee_id=? AND month=? AND year=?', whereArgs: [e['id'], month, year])).first;
      final rate = n(pay['daily_rate']); final absent = n(pay['absent_days']);
      final gross = roundHalfUp(rate * days, 2); final recovery = roundHalfUp(rate * absent, 2);
      out.add({...e, ...pay, 'month_days': days, 'gross': gross, 'recovery': recovery, 'net': roundHalfUp(gross - recovery, 2)});
    }
    return out;
  }

  Future<void> saveDailyCell(int id, int month, int year, String field, double value) async {
    _validatePeriod(month, year);
    if (!{'daily_rate', 'absent_days'}.contains(field) || !value.isFinite || value < 0) throw ArgumentError('Invalid daily-wage value.');
    if (field == 'absent_days' && value > DateTime(year, month + 1, 0).day) throw ArgumentError('Absent days cannot exceed days in month.');
    final d = await db;
    await d.insert('daily_wage_payroll', {'employee_id': id, 'month': month, 'year': year, 'daily_rate': 300, 'absent_days': 0}, conflictAlgorithm: ConflictAlgorithm.ignore);
    await d.update('daily_wage_payroll', {field: value}, where: 'employee_id=? AND month=? AND year=?', whereArgs: [id, month, year]);
  }

  Future<List<Map<String, Object?>>> retirementSchedule({DateTime? today}) async {
    final now = today ?? DateTime.now();
    final people = await employees(activeOnly: true);
    final settings = await (await db).query('retirement_age_settings');
    final ageByPost = {for (final s in settings) '${s['designation']}'.toLowerCase(): (s['retirement_age'] as num).toInt()};
    final out = <Map<String, Object?>>[];
    for (final e in people) {
      final dob = '${e['dob'] ?? ''}';
      if (dob.isEmpty) continue;
      final birth = DateTime.tryParse(dob);
      if (birth == null) continue;
      final age = ageByPost['${e['designation'] ?? ''}'.toLowerCase()] ?? 60;
      final year = birth.year + age;
      final day = min(birth.day, DateTime(year, birth.month + 1, 0).day);
      final retirement = DateTime(year, birth.month, day);
      out.add({...e, 'retirement_age': age, 'retirement_date': retirement.toIso8601String().substring(0, 10), 'days_remaining': retirement.difference(DateTime(now.year, now.month, now.day)).inDays, 'retired': !retirement.isAfter(DateTime(now.year, now.month, now.day))});
    }
    out.sort((a,b) => n(a['days_remaining']).compareTo(n(b['days_remaining'])));
    return out;
  }

  Future<List<Map<String, Object?>>> retirementSettings() async => (await db).query('retirement_age_settings', orderBy: 'designation');
  Future<void> saveRetirementAge(String designation, int age) async {
    if (designation.trim().isEmpty || age < 1 || age > 100) throw ArgumentError('Designation and valid age are required.');
    await (await db).insert('retirement_age_settings', {'designation': designation.trim(), 'retirement_age': age}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Object?>> emailSettings() async {
    final d = await db;
    await d.insert('email_settings', {'id':1}, conflictAlgorithm: ConflictAlgorithm.ignore);
    return (await d.query('email_settings', where: 'id=1')).first;
  }
  Future<void> saveEmailSettings(Map<String, Object?> values) async {
    final d = await db;
    await d.insert('email_settings', {'id':1, ...values}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> savePassword(String password) async => _setPassword(await db, password);
  Future<bool> verifyPassword(String password) async {
    final rows = await (await db).query('app_settings', where: 'key=?', whereArgs: ['password_hash']);
    if (rows.isEmpty) return password == 'admin';
    final bits = '${rows.first['value']}'.split(':');
    if (bits.length != 2) return false;
    try {
      final salt = base64Decode(bits[0]);
      return sha256.convert([...salt, ...utf8.encode(password)]).toString() == bits[1];
    } catch (_) { return false; }
  }

  Future<String> databasePath() async => p.join((await getApplicationDocumentsDirectory()).path, 'payroll.db');
  Future<void> replaceDatabase(List<int> bytes) async {
    if (bytes.length < 16 || String.fromCharCodes(bytes.take(15)) != 'SQLite format 3') throw StateError('Selected file is not a SQLite database.');
    final path = await databasePath();
    final old = _db;
    if (old != null) { await old.close(); _db = null; }
    final file = File(path); final backup = File('$path.backup');
    if (await file.exists()) await file.copy(backup.path);
    try {
      await file.writeAsBytes(bytes, flush: true);
      final check = await openDatabase(path, version: 5, onConfigure: (d) async => d.execute('PRAGMA foreign_keys=ON'), onUpgrade: (d, oldV, newV) async { await _ensureSchema(d); await _ensureColumns(d); });
      final tables = await check.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='employees'");
      if (tables.isEmpty) throw StateError('SQLite file does not contain payroll employee data.');
      await check.close();
      _db = await _open();
    } catch (_) {
      if (await backup.exists()) await backup.copy(path);
      _db = null;
      rethrow;
    }
  }

  Future<void> close() async { await _db?.close(); _db = null; }
}

void _validatePeriod(int month, int year) {
  if (month < 1 || month > 12 || year < 1900 || year > 2100) throw ArgumentError('Invalid month/year.');
}

double n(Object? x) => x is num ? x.toDouble() : double.tryParse('$x') ?? 0;
double roundHalfUp(double value, [int places = 0]) {
  final factor = pow(10, places).toDouble();
  return (value * factor).roundToDouble() / factor;
}
double roundEven(double value, [int places = 0]) {
  final scale = pow(10, places).toDouble();
  final scaled = value * scale; final floorValue = scaled.floorToDouble(); final fraction = scaled - floorValue;
  if ((fraction - .5).abs() < 1e-10) return (floorValue.toInt().isEven ? floorValue : floorValue + 1) / scale;
  return scaled.roundToDouble() / scale;
}
Map<String, Object?> calculate(Map<String, Object?> source, Map<String, Object?> tax, int days) {
  final x = Map<String, Object?>.from(source); final basic = n(x['basic']);
  final living = (x['living_enabled'] ?? 1) == 1 ? roundEven(basic * .10) : 0.0;
  final gp = (x['gp_enabled'] ?? 1) == 1 ? roundEven(basic * .0833) : 0.0;
  final gross = basic + n(x['leave_salary']) + n(x['substitution_salary']) + living + n(x['da']) + gp;
  final recovery = n(x['recovery_days']) > 0 ? roundHalfUp(gross / max(days, 1) * n(x['recovery_days']), 2) : n(x['recovery']);
  final pt = x['gender'] == 'female' ? n(tax['women_amount']) : (basic > n(tax['threshold']) ? n(tax['above_amount']) : n(tax['below_amount']));
  final balance = gross - n(x['future_payable']) - recovery;
  final deductions = gp * 2 + n(x['loan']) + pt + n(x['insurance']) + n(x['festival_advance']) + n(x['grain_advance']) + n(x['society']) + n(x['other']);
  final net = max(0, roundHalfUp(balance - deductions));
  x.addAll({'living': living, 'gp': gp, 'gross': gross, 'recovery_amount': recovery, 'professional_tax': pt, 'pf_employee': gp, 'pf_employer': gp, 'balance': balance, 'deductions': deductions, 'net': net});
  return x;
}

extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
