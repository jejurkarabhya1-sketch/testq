import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PayrollDb {
  PayrollDb._();
  static final PayrollDb instance = PayrollDb._();
  Database? _db;
  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    return openDatabase(p.join(dir.path, 'payroll.db'), version: 3,
      onCreate: (d, _) async {
        final existing = await d.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='employees'");
        if (existing.isNotEmpty) {
          await d.execute('CREATE TABLE IF NOT EXISTS app_settings(key TEXT PRIMARY KEY,value TEXT)');
          final saved = await d.query('app_settings', where: 'key=?', whereArgs: ['password_hash']);
          if (saved.isEmpty) { final salt=List<int>.generate(16, (_) => Random.secure().nextInt(256)); await d.insert('app_settings', {'key':'password_hash','value':'${base64Encode(salt)}:${sha256.convert([...salt,...utf8.encode('admin')])}'}); }
          await d.execute('CREATE TABLE IF NOT EXISTS retirement_age_settings(designation TEXT PRIMARY KEY COLLATE NOCASE,retirement_age INTEGER NOT NULL)');
          return;
        }
        await d.execute('''CREATE TABLE employees(id INTEGER PRIMARY KEY AUTOINCREMENT,name_marathi TEXT,name_english TEXT,designation TEXT,department TEXT,gender TEXT NOT NULL DEFAULT 'unspecified',dob TEXT,pay_scale TEXT,basic REAL DEFAULT 0,leave_salary REAL DEFAULT 0,substitution_salary REAL DEFAULT 0,living_enabled INTEGER DEFAULT 1,da REAL DEFAULT 0,gp_enabled INTEGER DEFAULT 1,future_payable REAL DEFAULT 0,recovery REAL DEFAULT 0,recovery_days REAL DEFAULT 0,pf_employee REAL DEFAULT 0,pf_employer REAL DEFAULT 0,loan REAL DEFAULT 0,professional_tax REAL DEFAULT 0,insurance REAL DEFAULT 0,festival_advance REAL DEFAULT 0,grain_advance REAL DEFAULT 0,society REAL DEFAULT 0,other REAL DEFAULT 0,account_number TEXT,ifsc TEXT,bank TEXT,branch TEXT,sort_order INTEGER DEFAULT 0,is_active INTEGER DEFAULT 1,gram_salary_account TEXT DEFAULT '',gram_salary_ifsc TEXT DEFAULT '',gram_ppf_account TEXT DEFAULT '',gram_ppf_ifsc TEXT DEFAULT '',water_salary_account TEXT DEFAULT '',water_salary_ifsc TEXT DEFAULT '',water_ppf_account TEXT DEFAULT '',water_ppf_ifsc TEXT DEFAULT '')''');
        await d.execute('CREATE TABLE payroll_periods(id INTEGER PRIMARY KEY AUTOINCREMENT,month INTEGER,year INTEGER,created TEXT DEFAULT CURRENT_TIMESTAMP,UNIQUE(month,year))');
        await d.execute('CREATE TABLE payroll_entries(id INTEGER PRIMARY KEY AUTOINCREMENT,period_id INTEGER,employee_id INTEGER,snapshot TEXT,UNIQUE(period_id,employee_id))');
        await d.execute('''CREATE TABLE daily_wage_employees(id INTEGER PRIMARY KEY AUTOINCREMENT,name TEXT NOT NULL,account_number TEXT NOT NULL,ifsc TEXT NOT NULL,bank_name TEXT DEFAULT '',branch TEXT DEFAULT '',employee_type TEXT NOT NULL,is_active INTEGER NOT NULL DEFAULT 1)''');
        await d.execute('CREATE TABLE daily_wage_payroll(id INTEGER PRIMARY KEY AUTOINCREMENT,employee_id INTEGER,month INTEGER,year INTEGER,daily_rate REAL DEFAULT 300,absent_days REAL DEFAULT 0,UNIQUE(employee_id,month,year))');
        await d.execute('CREATE TABLE professional_tax_settings(id INTEGER PRIMARY KEY CHECK(id=1),threshold REAL NOT NULL,below_amount REAL NOT NULL,above_amount REAL NOT NULL,women_amount REAL NOT NULL)');
        await d.insert('professional_tax_settings', {'id':1,'threshold':10000,'below_amount':175,'above_amount':200,'women_amount':0});
        await d.execute('CREATE TABLE retirement_age_settings(designation TEXT PRIMARY KEY COLLATE NOCASE,retirement_age INTEGER NOT NULL)');
        await d.execute('CREATE TABLE app_settings(key TEXT PRIMARY KEY,value TEXT)');
        final salt=List<int>.generate(16, (_) => Random.secure().nextInt(256));
        await d.insert('app_settings', {'key':'password_hash','value':'${base64Encode(salt)}:${sha256.convert([...salt,...utf8.encode('admin')])}'});
      },
      onUpgrade: (d, old, newV) async {
        if (old < 2) { await d.execute("ALTER TABLE employees ADD COLUMN gender TEXT NOT NULL DEFAULT 'unspecified'"); await d.execute('ALTER TABLE employees ADD COLUMN dob TEXT'); }
        if (old < 3) { await d.execute("CREATE TABLE IF NOT EXISTS app_settings(key TEXT PRIMARY KEY,value TEXT)"); await d.execute('CREATE TABLE IF NOT EXISTS retirement_age_settings(designation TEXT PRIMARY KEY COLLATE NOCASE,retirement_age INTEGER NOT NULL)'); }
      });
  }

  Future<List<Map<String,Object?>>> employees({bool activeOnly=false}) async => (await db).query('employees', where: activeOnly ? 'is_active=1' : null, orderBy: 'department,sort_order,id');
  Future<int> saveEmployee(Map<String,Object?> v) async { final d=await db; const allowed={'name_marathi','name_english','designation','department','gender','dob','pay_scale','basic','leave_salary','substitution_salary','living_enabled','da','gp_enabled','future_payable','recovery','recovery_days','pf_employee','pf_employer','loan','professional_tax','insurance','festival_advance','grain_advance','society','other','account_number','ifsc','bank','branch','sort_order','is_active','gram_salary_account','gram_salary_ifsc','gram_ppf_account','gram_ppf_ifsc','water_salary_account','water_salary_ifsc','water_ppf_account','water_ppf_ifsc'}; final clean=<String,Object?>{for(final e in v.entries) if(allowed.contains(e.key)) e.key:e.value}; final id=v['id']; if(id==null) return d.insert('employees', clean); await d.update('employees',clean,where:'id=?',whereArgs:[id]); return id as int; }
  Future<void> deactivateEmployee(int id) async => (await db).update('employees',{'is_active':0},where:'id=?',whereArgs:[id]);
  Future<Map<String,Object?>> taxSettings() async => (await db).query('professional_tax_settings',limit:1).then((r)=>r.first);
  Future<void> saveTax(Map<String,Object?> v) async => (await db).update('professional_tax_settings',v,where:'id=1');
  Future<List<Map<String,Object?>>> dailyEmployees({bool activeOnly=false}) async => (await db).query('daily_wage_employees',where:activeOnly?'is_active=1':null,orderBy:'id');
  Future<int> saveDailyEmployee(Map<String,Object?> v) async => (await db).insert('daily_wage_employees',v);
  Future<void> deactivateDaily(int id) async => (await db).update('daily_wage_employees',{'is_active':0},where:'id=?',whereArgs:[id]);
  Future<List<Map<String,Object?>>> dailyRows(int month,int year) async {
    final d=await db; final people=await dailyEmployees(activeOnly:true); final days=DateTime(year,month+1,0).day; final out=<Map<String,Object?>>[];
    for(final e in people){ await d.insert('daily_wage_payroll',{'employee_id':e['id'],'month':month,'year':year,'daily_rate':300,'absent_days':0},conflictAlgorithm:ConflictAlgorithm.ignore); final pay=(await d.query('daily_wage_payroll',where:'employee_id=? AND month=? AND year=?',whereArgs:[e['id'],month,year])).first; final gross=(pay['daily_rate'] as num).toDouble()*days; final absent=(pay['absent_days'] as num).toDouble(); out.add({...e,...pay,'month_days':days,'gross':gross,'recovery':(pay['daily_rate'] as num).toDouble()*absent,'net':gross-(pay['daily_rate'] as num).toDouble()*absent}); }
    return out;
  }
  Future<void> saveDailyCell(int id,int month,int year,String field,double value) async { final d=await db; await d.insert('daily_wage_payroll',{'employee_id':id,'month':month,'year':year,'daily_rate':300,'absent_days':0},conflictAlgorithm:ConflictAlgorithm.ignore); await d.update('daily_wage_payroll',{field:value},where:'employee_id=? AND month=? AND year=?',whereArgs:[id,month,year]); }
  Future<void> savePassword(String password) async { final d=await db; final salt=List<int>.generate(16, (_) => Random.secure().nextInt(256)); await d.insert('app_settings',{'key':'password_hash','value':'${base64Encode(salt)}:${sha256.convert([...salt,...utf8.encode(password)])}'},conflictAlgorithm:ConflictAlgorithm.replace); }
  Future<bool> verifyPassword(String password) async { final d=await db; final rows=await d.query('app_settings',where:'key=?',whereArgs:['password_hash']); if(rows.isEmpty)return password=='admin'; final bits=(rows.first['value'] as String).split(':'); final salt=base64Decode(bits[0]); return sha256.convert([...salt,...utf8.encode(password)]).toString()==bits[1]; }
  Future<String> databasePath() async { final dir=await getApplicationDocumentsDirectory(); return p.join(dir.path,'payroll.db'); }
  Future<void> replaceDatabase(List<int> bytes) async { final path=await databasePath(); final old=_db; if(old!=null){await old.close();_db=null;} final file=File(path); if(await file.exists()) await file.copy('$path.backup'); await file.writeAsBytes(bytes,flush:true); try { final check=await openDatabase(path, readOnly:true); final tables=await check.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='employees'"); await check.close(); if(tables.isEmpty) throw StateError('SQLite file does not contain payroll employee data'); await db; } catch(e) { if(await File('$path.backup').exists()) await File('$path.backup').copy(path); _db=null; rethrow; } }
}

double n(Object? x) => x is num ? x.toDouble() : double.tryParse('$x') ?? 0;
double roundEven(double value, [int places=0]) { final scale=pow(10, places).toDouble(); final scaled=value*scale; final floorValue=scaled.floorToDouble(); final fraction=scaled-floorValue; double rounded; if ((fraction-0.5).abs()<1e-10) { rounded=floorValue.toInt().isEven ? floorValue : floorValue+1; } else { rounded=scaled.roundToDouble(); } return rounded/scale; }
Map<String,Object?> calculate(Map<String,Object?> r, Map<String,Object?> tax, int days) {
  final x=Map<String,Object?>.from(r); final basic=n(x['basic']); final living=(x['living_enabled']??1)==1?roundEven(basic*.10):0.0; final gp=(x['gp_enabled']??1)==1?roundEven(basic*.0833):0.0;
  final gross=basic+n(x['leave_salary'])+n(x['substitution_salary'])+living+n(x['da'])+gp;
  final recovery=n(x['recovery_days'])>0 ? roundEven(gross/days*n(x['recovery_days']),2) : n(x['recovery']);
  final gender=x['gender']; final pt=gender=='female'?n(tax['women_amount']):(basic>n(tax['threshold'])?n(tax['above_amount']):n(tax['below_amount']));
  final balance=gross-n(x['future_payable'])-recovery; final deductions=gp*2+n(x['loan'])+pt+n(x['insurance'])+n(x['festival_advance'])+n(x['grain_advance'])+n(x['society'])+n(x['other']);
  x.addAll({'living':living,'gp':gp,'gross':gross,'recovery_amount':recovery,'professional_tax':pt,'pf_employee':gp,'pf_employer':gp,'balance':balance,'deductions':deductions,'net':max(0,(balance-deductions).round())}); return x;
}
