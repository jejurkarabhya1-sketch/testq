import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'database.dart';

void main() => runApp(const LasalgaonApp());
String money(Object? v) => NumberFormat.currency(locale:'en_IN',symbol:'₹',decimalDigits:0).format(n(v));
const departments=['ग्रामनिधी','पाणी पुरवठा'];
const monthNames=['जानेवारी','फेब्रुवारी','मार्च','एप्रिल','मे','जून','जुलै','ऑगस्ट','सप्टेंबर','ऑक्टोबर','नोव्हेंबर','डिसेंबर'];
const salaryFields=<String,String>{'basic':'मूळ वेतन','leave_salary':'रजा वेतन','substitution_salary':'स्थानार्पण वेतन','da':'महागाई / सानुग्रह अनुदान','future_payable':'पुढील अधिदानासाठी ठेवलेली रक्कम','recovery_days':'वसुली दिवस','loan':'हप्ता / कर्ज','insurance':'विमा','festival_advance':'सन अग्रिम','grain_advance':'धान्य अग्रिम','society':'कर्मचारी सोसायटी','other':'इतर वजाती'};

class LasalgaonApp extends StatelessWidget { const LasalgaonApp({super.key}); @override Widget build(BuildContext context)=>MaterialApp(title:'लासलगाव ग्रामपंचायत वेतन',debugShowCheckedModeBanner:false,theme:ThemeData(colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff7d1d2b)),useMaterial3:true,scaffoldBackgroundColor:const Color(0xfff7f7fa),inputDecorationTheme:const InputDecorationTheme(border:OutlineInputBorder())),home:const Gate()); }
class Gate extends StatefulWidget { const Gate({super.key}); @override State<Gate> createState()=>_GateState(); }
class _GateState extends State<Gate>{bool logged=false; final pass=TextEditingController(); String error=''; @override Widget build(BuildContext c){if(logged)return const Home(); return Scaffold(body:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:420),child:Card(margin:const EdgeInsets.all(24),child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.account_balance,size:58,color:Color(0xff7d1d2b)),const SizedBox(height:12),Text('लासलगाव ग्रामपंचायत',style:Theme.of(c).textTheme.headlineSmall),const Text('वेतन व्यवस्थापन'),const SizedBox(height:24),TextField(controller:pass,obscureText:true,decoration:const InputDecoration(labelText:'पासवर्ड',prefixIcon:Icon(Icons.lock)),onSubmitted:(_)=>login()),if(error.isNotEmpty) Text(error,style:const TextStyle(color:Colors.red)),const SizedBox(height:12),FilledButton(onPressed:login,child:const Text('लॉगिन'))]))))));} Future<void> login() async {if(await PayrollDb.instance.verifyPassword(pass.text)){setState(()=>logged=true);}else setState(()=>error='पासवर्ड चुकीचा आहे');} }

class Home extends StatefulWidget {const Home({super.key});@override State<Home> createState()=>_HomeState();}
class _HomeState extends State<Home>{int tab=0;int month=DateTime.now().month,year=DateTime.now().year; String dept=departments.first; void refresh()=>setState((){}); @override Widget build(BuildContext c){final pages=[Dashboard(month:month,year:year,onOpen:(i)=>setState(()=>tab=i)),PayrollScreen(month:month,year:year,dept:dept,onDept:(v)=>setState(()=>dept=v),refresh:refresh),EmployeesScreen(refresh:refresh),DailyScreen(month:month,year:year,refresh:refresh),ReportsScreen(month:month,year:year),SettingsScreen()];return Scaffold(appBar:AppBar(title:const Text('लासलगाव ग्रामपंचायत'),actions:[DropdownButton<int>(value:month,underline:const SizedBox(),items:List.generate(12,(i)=>DropdownMenuItem(value:i+1,child:Text(monthNames[i]))) ,onChanged:(v)=>setState(()=>month=v!)),DropdownButton<int>(value:year,underline:const SizedBox(),items:List.generate(21,(i)=>DropdownMenuItem(value:DateTime.now().year-10+i,child:Text('${DateTime.now().year-10+i}'))) ,onChanged:(v)=>setState(()=>year=v!)),const SizedBox(width:8)]),body:IndexedStack(index:tab,children:pages),bottomNavigationBar:NavigationBar(selectedIndex:tab,onDestinationSelected:(v)=>setState(()=>tab=v),destinations:const [NavigationDestination(icon:Icon(Icons.dashboard_outlined),selectedIcon:Icon(Icons.dashboard),label:'डॅशबोर्ड'),NavigationDestination(icon:Icon(Icons.calculate_outlined),label:'वेतन'),NavigationDestination(icon:Icon(Icons.people_outline),label:'कर्मचारी'),NavigationDestination(icon:Icon(Icons.calendar_month),label:'रोजंदार'),NavigationDestination(icon:Icon(Icons.description_outlined),label:'अहवाल'),NavigationDestination(icon:Icon(Icons.settings_outlined),label:'सेटिंग') ]));}}

class Dashboard extends StatelessWidget {final int month,year;final ValueChanged<int> onOpen;const Dashboard({super.key,required this.month,required this.year,required this.onOpen});@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,Object?>>>(future:PayrollDb.instance.employees(activeOnly:true),builder:(c,s){final rows=s.data??[];final active=rows.length;final gross=rows.fold<double>(0,(a,r)=>a+n(r['basic']));return ListView(padding:const EdgeInsets.all(16),children:[Text('नमस्कार! 👋',style:Theme.of(c).textTheme.headlineMedium),Text('$month/$year वेतन कालावधी',style:Theme.of(c).textTheme.titleMedium),const SizedBox(height:16),Wrap(spacing:12,runSpacing:12,children:[_stat('सक्रिय कर्मचारी','$active',Icons.people),_stat('एकूण मूळ वेतन',money(gross),Icons.payments),_stat('वेतन महिना','$month/$year',Icons.calendar_month),_stat('रोजंदार कर्मचारी','स्थानिक डेटाबेस',Icons.groups)]),const SizedBox(height:20),Text('जलद कृती',style:Theme.of(c).textTheme.titleLarge),const SizedBox(height:8),_action(c,'मासिक वेतन नोंद','वेतन तपासा आणि बदल करा',Icons.calculate,()=>onOpen(1)),_action(c,'कर्मचारी व्यवस्थापन','कर्मचारी जोडा, संपादित करा किंवा निष्क्रिय करा',Icons.people,()=>onOpen(2)),_action(c,'वेतन अहवाल','Excel किंवा PDF अहवाल तयार करा',Icons.file_present,()=>onOpen(4)),const SizedBox(height:16),const Card(child:Padding(padding:EdgeInsets.all(14),child:Text('टीप: पहिल्या वापरावेळी डीफॉल्ट पासवर्ड admin आहे. सेटिंग्जमध्ये तो त्वरित बदला.')))]);});Widget _stat(String title,String value,IconData icon)=>SizedBox(width:160,child:Card(child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:const Color(0xff7d1d2b)),const SizedBox(height:8),Text(title),Text(value,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))]))));Widget _action(BuildContext c,String title,String subtitle,IconData icon,VoidCallback f)=>Card(child:ListTile(leading:Icon(icon,color:const Color(0xff7d1d2b)),title:Text(title),subtitle:Text(subtitle),trailing:const Icon(Icons.chevron_right),onTap:f));}

class PayrollScreen extends StatefulWidget {final int month,year;final String dept;final ValueChanged<String> onDept;final VoidCallback refresh;const PayrollScreen({super.key,required this.month,required this.year,required this.dept,required this.onDept,required this.refresh});@override State<PayrollScreen> createState()=>_PayrollScreenState();}
class _PayrollScreenState extends State<PayrollScreen>{Future<List<Map<String,Object?>>> load()async=>PayrollDb.instance.periodRows(widget.month,widget.year,department:widget.dept); @override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:SegmentedButton<String>(segments:const [ButtonSegment(value:'ग्रामनिधी',label:Text('ग्रामनिधी')),ButtonSegment(value:'पाणी पुरवठा',label:Text('पाणी पुरवठा'))],selected:{widget.dept},onSelectionChanged:(v)=>widget.onDept(v.first))),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:load(),builder:(c,s){if(!s.hasData)return const Center(child:CircularProgressIndicator());final rows=s.data!;final total=rows.fold<double>(0,(a,r)=>a+n(r['net']));if(rows.isEmpty)return const Center(child:Text('कर्मचारी नाहीत. कर्मचारी विभागातून नोंद जोडा.'));return Column(children:[Card(child:ListTile(title:const Text('एकूण निव्वळ वेतन'),trailing:Text(money(total),style:Theme.of(c).textTheme.titleLarge))),Expanded(child:ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ExpansionTile(title:Text('${i+1}. ${r['name_marathi']??''}'),subtitle:Text('${r['designation']??''}  •  निव्वळ: ${money(r['net'])}'),children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[_line('मूळ वेतन',r['basic']),_line('एकूण वेतन',r['gross']),_line('वसुली',r['recovery_amount']),_line('व्यवसाय कर',r['professional_tax']),_line('एकूण वजाती',r['deductions']),_line('निव्वळ वेतन',r['net']),const SizedBox(height:8),Wrap(spacing:8,children:[FilledButton.icon(onPressed:()=>_edit(c,r),icon:const Icon(Icons.edit),label:const Text('वेतन बदला')),OutlinedButton.icon(onPressed:()=>_editEmployee(c,r),icon:const Icon(Icons.account_balance),label:const Text('बँक तपशील'))])]))]));}))]);}))]);}
Widget _line(String k,Object? v)=>Padding(padding:const EdgeInsets.symmetric(vertical:3),child:Row(children:[Expanded(child:Text(k)),Text(money(v),style:const TextStyle(fontWeight:FontWeight.w600))]));
Future<void> _edit(BuildContext context,Map<String,Object?> row)async{final fields=salaryFields.entries.toList();final ctrls={for(final e in fields)e.key:TextEditingController(text:'${row[e.key]??0}')};await showDialog(context:context,builder:(d)=>AlertDialog(title:Text('${row['name_marathi']} — वेतन'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:fields.map((e)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:ctrls[e.key],keyboardType:TextInputType.number,decoration:InputDecoration(labelText:e.value)))).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{final patch=<String,Object?>{};for(final e in fields){patch[e.key]=double.tryParse(ctrls[e.key]!.text)??0;}for(final e in patch.entries){await PayrollDb.instance.savePeriodCell(row['id'] as int,e.key,e.value,widget.month,widget.year);}if(context.mounted){Navigator.pop(d);setState((){});widget.refresh();}},child:const Text('जतन करा'))]));}
Future<void> _editEmployee(BuildContext context,Map<String,Object?> row)async{final fields={'gram_salary_account':'ग्रामनिधी Salary Account','gram_salary_ifsc':'ग्रामनिधी Salary IFSC','gram_ppf_account':'ग्रामनिधी PPF Account','gram_ppf_ifsc':'ग्रामनिधी PPF IFSC','water_salary_account':'पाणी पुरवठा Salary Account','water_salary_ifsc':'पाणी पुरवठा Salary IFSC','water_ppf_account':'पाणी पुरवठा PPF Account','water_ppf_ifsc':'पाणी पुरवठा PPF IFSC'};final cs={for(final k in fields.keys)k:TextEditingController(text:'${row[k]??''}')};await showDialog(context:context,builder:(d)=>AlertDialog(title:const Text('बँक खाते तपशील'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:fields.entries.map((e)=>TextField(controller:cs[e.key],decoration:InputDecoration(labelText:e.value))).toList()))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{await PayrollDb.instance.saveEmployee({...row,...{for(final k in fields.keys)k:cs[k]!.text}});if(context.mounted){Navigator.pop(d);setState((){});widget.refresh();}},child:const Text('जतन करा'))]));}}

class EmployeesScreen extends StatefulWidget {final VoidCallback refresh;const EmployeesScreen({super.key,required this.refresh});@override State<EmployeesScreen> createState()=>_EmployeesScreenState();}
class _EmployeesScreenState extends State<EmployeesScreen>{String dept=departments.first;@override Widget build(BuildContext c)=>Column(children:[Padding(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:DropdownButtonFormField(value:dept,items:departments.map((d)=>DropdownMenuItem(value:d,child:Text(d))).toList(),onChanged:(v)=>setState(()=>dept=v!),decoration:const InputDecoration(labelText:'विभाग'))),const SizedBox(width:10),FilledButton.icon(onPressed:()=>_form(c),icon:const Icon(Icons.person_add),label:const Text('नवीन'))])),Expanded(child:FutureBuilder<List<Map<String,Object?>>>(future:PayrollDb.instance.employees(),builder:(c,s){final rows=(s.data??[]).where((r)=>r['department']==dept).toList();return ListView.builder(itemCount:rows.length,itemBuilder:(c,i){final r=rows[i];return Card(child:ListTile(title:Text('${r['name_marathi']??''}'),subtitle:Text('${r['designation']??''} • ${r['gender']??'unspecified'} • ${r['is_active']==1?'सक्रिय':'निष्क्रिय'}'),onTap:()=>_form(c,existing:r),trailing:PopupMenuButton<String>(onSelected:(v)async{if(v=='disable')await PayrollDb.instance.deactivateEmployee(r['id'] as int);else await _form(c,existing:r);setState((){});},itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('संपादित करा')),PopupMenuItem(value:'disable',child:Text('निष्क्रिय करा'))])));});}))]);Future<void> _form(BuildContext c,{Map<String,Object?>? existing})async{final fields=['name_marathi','name_english','designation','pay_scale','basic','leave_salary','substitution_salary','da','future_payable','recovery','recovery_days','loan','insurance','festival_advance','grain_advance','society','other','gender','dob','account_number','ifsc','bank','branch',...bankFields];final labels=['नाव (मराठी)','नाव (English)','पद','वेतनश्रेणी','मूळ वेतन','रजा वेतन','स्थानार्पण वेतन','महागाई भत्ता','पुढील अधिदानासाठी ठेव','निश्चित वसुली','वसुली दिवस','कर्ज हप्ता','विमा','सन अग्रिम','धान्य अग्रिम','सोसायटी','इतर वजाती','लिंग (male/female/unspecified)','जन्मतारीख (YYYY-MM-DD)','बँक खाते','IFSC','बँक','शाखा','ग्रामनिधी वेतन खाते','ग्रामनिधी वेतन IFSC','ग्रामनिधी PPF खाते','ग्रामनिधी PPF IFSC','पाणीपुरवठा वेतन खाते','पाणीपुरवठा वेतन IFSC','पाणीपुरवठा PPF खाते','पाणीपुरवठा PPF IFSC'];final cs={for(final k in fields)k:TextEditingController(text:'${existing?[k]??(k=='gender'?'unspecified':'')}')};String selected=existing?['department'] as String? ?? dept;await showDialog(context:c,builder:(d)=>AlertDialog(title:Text(existing==null?'कर्मचारी जोडा':'कर्मचारी संपादित करा'),content:SizedBox(width:460,child:SingleChildScrollView(child:Column(children:[DropdownButtonFormField(value:selected,items:departments.map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>selected=v!,decoration:const InputDecoration(labelText:'विभाग')),...List.generate(fields.length,(i)=>Padding(padding:const EdgeInsets.only(top:8),child:TextField(controller:cs[fields[i]],keyboardType:!['name_marathi','name_english','designation','pay_scale','gender','dob','account_number','ifsc','bank','branch',...bankFields].contains(fields[i])?TextInputType.number:TextInputType.text,decoration:InputDecoration(labelText:labels[i]))))]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{final v=<String,Object?>{for(final k in fields)k:cs[k]!.text};for(final k in ['basic','leave_salary','substitution_salary','da','future_payable','recovery','recovery_days','loan','insurance','festival_advance','grain_advance','society','other'])v[k]=double.tryParse('${v[k]}')??0;v.addAll({'department':selected,'is_active': existing != null ? (existing['is_active'] as int? ?? 1) : 1,'living_enabled': existing != null ? (existing['living_enabled'] as int? ?? 1) : 1,'gp_enabled': existing != null ? (existing['gp_enabled'] as int? ?? 1) : 1,'sort_order': existing != null ? (existing['sort_order'] as int? ?? 0) : 0});if(existing!=null)v['id']=existing['id'];await PayrollDb.instance.saveEmployee(v);if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}}

class DailyScreen extends StatefulWidget{final int month,year;final VoidCallback refresh;const DailyScreen({super.key,required this.month,required this.year,required this.refresh});@override State<DailyScreen> createState()=>_DailyScreenState();}
class _DailyScreenState extends State<DailyScreen> {
  @override
  Widget build(BuildContext c) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: Text('रोजंदार वेतन',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                FilledButton.icon(
                  onPressed: () => _add(c),
                  icon: const Icon(Icons.add),
                  label: const Text('कर्मचारी जोडा'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, Object?>>>(
              future: PayrollDb.instance.dailyRows(widget.month, widget.year),
              builder: (c, s) {
                if (!s.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = s.data!;
                return ListView(
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                            'महिन्याचे दिवस: ${DateTime(widget.year, widget.month + 1, 0).day}'),
                        subtitle: Text('${widget.month}/${widget.year}'),
                      ),
                    ),
                    ...rows.map(
                      (r) => Card(
                        child: ExpansionTile(
                          title: Text('${r['name']}'),
                          subtitle: Text(
                              '${r['employee_type']} • निव्वळ ${money(r['net'])}'),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _line('एकूण वेतन', r['gross']),
                                  _line('वसुली', r['recovery']),
                                  _line('निव्वळ वेतन', r['net']),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => _cell(
                                              c, r, 'daily_rate', 'दैनिक दर'),
                                          child: Text(
                                              'दर: ${money(r['daily_rate'])}'),
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () => _cell(c, r,
                                              'absent_days', 'अनुपस्थित दिवस'),
                                          child: Text(
                                              'गैरहजर: ${r['absent_days']}'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      );

  Future<void> _cell(BuildContext c,Map<String,Object?> r,String field,String label)async{final ctl=TextEditingController(text:'${r[field]}');await showDialog(context:c,builder:(d)=>AlertDialog(title:Text(label),content:TextField(controller:ctl,keyboardType:TextInputType.number),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{final v=double.tryParse(ctl.text)??0;await PayrollDb.instance.saveDailyCell(r['id'] as int,widget.month,widget.year,field,v);if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}Future<void> _add(BuildContext c)async{final name=TextEditingController(),acc=TextEditingController(),ifsc=TextEditingController(),bank=TextEditingController(),branch=TextEditingController();String type='इतर';await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('रोजंदार कर्मचारी'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(children:[for(final e in {'नाव':name,'खाते क्रमांक':acc,'IFSC':ifsc,'बँक':bank,'शाखा':branch}.entries)Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:e.value,decoration:InputDecoration(labelText:e.key))),DropdownButtonFormField(value:type,items:['शौचालय कर्मचारी','वाहनचालक','इतर'].map((x)=>DropdownMenuItem(value:x,child:Text(x))).toList(),onChanged:(v)=>type=v!)]))),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{if(name.text.trim().isEmpty||acc.text.trim().isEmpty||!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc.text.trim().toUpperCase())){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('नाव, खाते क्रमांक आणि वैध 11 अक्षरी IFSC आवश्यक आहे.')));return;}await PayrollDb.instance.saveDailyEmployee({'name':name.text.trim(),'account_number':acc.text.trim(),'ifsc':ifsc.text.toUpperCase(),'bank_name':bank.text,'branch':branch.text,'employee_type':type,'is_active':1});if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}}

class ReportsScreen extends StatelessWidget{final int month,year;const ReportsScreen({super.key,required this.month,required this.year});@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Text('अहवाल आणि निर्यात',style:Theme.of(c).textTheme.headlineSmall),const SizedBox(height:12),Card(child:ListTile(leading:const Icon(Icons.table_chart),title:const Text('Excel वेतन अहवाल'),subtitle:const Text('सहा वेतन/बँक शीट्स तयार करून शेअर करा'),trailing:const Icon(Icons.download),onTap:()=>_excel(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.email_outlined),title:const Text('ईमेलने वेतन अहवाल पाठवा'),subtitle:const Text('जतन केलेल्या SMTP/Gmail सेटिंगचा वापर'),trailing:const Icon(Icons.send),onTap:()=>_excel(c,month,year,email:true))),Card(child:ListTile(leading:const Icon(Icons.picture_as_pdf),title:const Text('PDF वेतन सारांश'),subtitle:const Text('प्रिंट किंवा PDF म्हणून जतन करा'),trailing:const Icon(Icons.print),onTap:()=>_pdf(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.payments_outlined),title:const Text('रोजंदार वेतन अहवाल'),subtitle:const Text('निवडलेल्या महिन्याचा दैनिक दर, गैरहजेरी आणि निव्वळ रक्कम'),onTap:()=>_dailyExcel(c,month,year))),Card(child:ListTile(leading:const Icon(Icons.backup),title:const Text('डेटाबेस बॅकअप'),subtitle:const Text('स्थानिक payroll.db फाईल शेअर करा'),onTap:()=>_backup(c))),const Padding(padding:EdgeInsets.all(12),child:Text('मुख्य Excel निर्यातीत सहा विभागीय/बँक शीट्स तयार होतात. मूळ डेस्कटॉप अॅपशी आकडे व स्वरूप तपासूनच अधिकृत वेतनासाठी वापरा.'))]);}
Future<void> _excel(BuildContext c,int m,int y,{bool email=false})async{
  try {
    final rows=await PayrollDb.instance.periodRows(m,y,activeOnly:true);
    final excel=Excel.createExcel();
    final sheetNames=['ग्रामनिधी','Gramnidhi Salary','Maharashtra Bank Gramnidhi PPF','पाणी पुरवठा','पाणी पुरवठा Salary','Maha Bank पाणी पुरवठा PPF'];
    excel.rename('Sheet1',sheetNames.first);
    final moneyFields=['basic','leave_salary','substitution_salary','living','da','gp','gross','future_payable','recovery_amount','balance','pf_employee','pf_employer','loan','professional_tax','insurance','festival_advance','grain_advance','society','other','deductions','net'];
    final headers=['अ.नं.','नाव','पद','वेतनश्रेणी','मूळ वेतन','रजा वेतन','स्थानार्पण वेतन','राहणीमान भत्ता 10%','महागाई / सानुग्रह अनुदान','ग्रामपंचायत हिस्सा 8.33%','एकूण वेतन','पुढील अधिदानासाठी ठेव','वसुली','शिल्लक','कर्मचारी PF','नियोक्ता PF','कर्ज हप्ता','व्यवसाय कर','विमा','सन अग्रिम','धान्य अग्रिम','सोसायटी','इतर','एकूण वजाती','निव्वळ वेतन','शेरा'];
    final mainSheets=[(sheetNames[0],'ग्रामनिधी'),(sheetNames[3],'पाणी पुरवठा')];
    for(final spec in mainSheets){
      final sh=excel[spec.$1];
      sh.appendRow([TextCellValue('लासलगाव ग्रामपंचायत — कर्मचाऱ्यांच्या वेतन देयकाची नोंदवही')]);
      sh.appendRow([TextCellValue('माहे ${monthNames[m-1]} $y')]);
      sh.appendRow(headers.map((v)=>TextCellValue(v)).toList());
      final deptRows=rows.where((r)=>r['department']==spec.$2).toList();
      for(var i=0;i<deptRows.length;i++){
        final r=deptRows[i];
        sh.appendRow([IntCellValue(i+1),TextCellValue('${r['name_marathi']??''}'),TextCellValue('${r['designation']??''}'),TextCellValue('${r['pay_scale']??''}'),...moneyFields.map((k)=>DoubleCellValue(n(r[k]))),TextCellValue('')]);
      }
      sh.appendRow([TextCellValue('एकूण'),TextCellValue(''),TextCellValue(''),TextCellValue(''),...moneyFields.map((k)=>DoubleCellValue(deptRows.fold<double>(0,(a,r)=>a+n(r[k])))),TextCellValue('')]);
      if(spec.$2=='ग्रामनिधी'){
        sh.appendRow([TextCellValue('तेरीज पत्रक सारांश')]);
        final admin=deptRows.where((r)=>n(r['sort_order'])>=1&&n(r['sort_order'])<=10).toList();
        final light=deptRows.where((r)=>n(r['sort_order'])>=11&&n(r['sort_order'])<=12).toList();
        final health=deptRows.where((r)=>n(r['sort_order'])>=13).toList();
        const sanctionedNames=['बाबासाहेब माणिकराव गिते','संतोष ताराचंद कोरे','समीर नासर बेग'];
        final sanctioned=deptRows.where((r)=>sanctionedNames.contains('${r['name_marathi']}')).toList();
        final essential=deptRows.where((r)=>!sanctionedNames.contains('${r['name_marathi']}')).toList();
        final categories=[('सामान्य प्रशासन',admin),('आरोग्य विभाग',health),('दिवाबत्ती विभाग',light),('एकूण',deptRows),('आकृतीबंध प्रमाणे सामान्य प्रशासन विभागात कार्यरत 3 कर्मचारी',sanctioned),('अत्यावश्यक सेवा ${essential.length} कर्मचारी',essential),('एकूण ${deptRows.length} कर्मचारी',deptRows)];
        for(final category in categories){sh.appendRow([TextCellValue(category.$1),TextCellValue(''),TextCellValue(''),TextCellValue(''),...moneyFields.map((k)=>DoubleCellValue(category.$2.fold<double>(0,(a,r)=>a+n(r[k])))),TextCellValue('')]);}
      }
      sh.setColumnWidth(1, 8); sh.setColumnWidth(2, 26); sh.setColumnWidth(3, 20);
    }
    for(final spec in [(sheetNames[1],'ग्रामनिधी','salary'),(sheetNames[2],'ग्रामनिधी','ppf'),(sheetNames[4],'पाणी पुरवठा','salary'),(sheetNames[5],'पाणी पुरवठा','ppf')]){
      final sh=excel[spec.$1]; final deptRows=rows.where((r)=>r['department']==spec.$2).toList();
      sh.appendRow([TextCellValue('GRAMPANCHAYAT LASALGAON')]);
      sh.appendRow([TextCellValue('माहे ${monthNames[m-1]} $y')]);
      final isPpf=spec.$3=='ppf';
      sh.appendRow((isPpf?['SR.NO.','NAME','A/C NO.','G.P.','EMPLOYEE','LOAN','AMT RS.']:['SR.NO.','NAME','A/C NO.','IFSC CODE','BANK NAME','BRANCH','AMT RS.']).map((v)=>TextCellValue(v)).toList());
      for(var i=0;i<deptRows.length;i++){
        final r=deptRows[i]; final prefix=spec.$2=='ग्रामनिधी'?'gram':'water';
        if(isPpf){sh.appendRow([IntCellValue(i+1),TextCellValue('${r['name_english']??r['name_marathi']??''}'),TextCellValue('${r['${prefix}_ppf_account']??''}'),DoubleCellValue(n(r['pf_employer'])),DoubleCellValue(n(r['pf_employee'])),DoubleCellValue(n(r['loan'])),DoubleCellValue(n(r['pf_employer'])+n(r['pf_employee'])+n(r['loan']))]);}
        else {sh.appendRow([IntCellValue(i+1),TextCellValue('${r['name_english']??r['name_marathi']??''}'),TextCellValue('${r['${prefix}_salary_account']??r['account_number']??''}'),TextCellValue('${r['${prefix}_salary_ifsc']??r['ifsc']??''}'),TextCellValue('${r['bank']??''}'),TextCellValue('${r['branch']??''}'),DoubleCellValue(n(r['net']))]);}
      }
    }
    final bytes=excel.encode(); if(bytes==null) throw StateError('Excel file could not be generated.');
    final dir=await getTemporaryDirectory(); final file=File('${dir.path}/Lasalgaon_Payroll_${y}_${m.toString().padLeft(2,'0')}.xlsx');
    await file.writeAsBytes(bytes,flush:true); if(email){await _sendWorkbookEmail(c,file,m,y);}else{await Share.shareXFiles([XFile(file.path)],text:'लासलगाव ग्रामपंचायत वेतन ${monthNames[m-1]} $y');}
  } catch(e) { if(c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('Excel निर्यात अयशस्वी: $e'))); }
}
Future<void> _sendWorkbookEmail(BuildContext c,File file,int month,int year)async{
 try{
  final config=await PayrollDb.instance.emailSettings(); const secure=FlutterSecureStorage(); final password=await secure.read(key:'smtp_app_password')??'';
  final from='${config['from_email']??''}'.trim(),to='${config['to_email']??''}'.trim();
  if(from.isEmpty||to.isEmpty||password.isEmpty){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('सेटिंग्जमध्ये पाठवणारा ईमेल, प्राप्तकर्ता आणि Gmail App Password जतन करा.')));return;}
  final server=SmtpServer('smtp.gmail.com',username:from,password:password,port:587,ssl:false,allowInsecure:false);
  final message=Message()..from=Address(from,'Lasalgaon Gram Panchayat')..recipients.add(to)..subject='Lasalgaon Gram Panchayat Salary ${monthNames[month-1]} $year'..text='Attached is the Lasalgaon Gram Panchayat salary workbook.'..attachments.add(FileAttachment(file)..fileName=file.uri.pathSegments.last);
  await send(message,server);
  if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('वेतन अहवाल $to येथे ईमेलने पाठवला.')));
 }catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('ईमेल पाठवता आला नाही: $e')));}
}
Future<void> _dailyExcel(BuildContext c,int m,int y)async{
 final rows=await PayrollDb.instance.dailyRows(m,y); final excel=Excel.createExcel(); final sh=excel['रोजंदार वेतन']; sh.appendRow(['नाव','प्रकार','बँक खाते','IFSC','दैनिक दर','महिन्याचे दिवस','गैरहजेरी','एकूण वेतन','वसुली','निव्वळ वेतन'].map((v)=>TextCellValue(v)).toList());
 for(final r in rows){sh.appendRow([TextCellValue('${r['name']}'),TextCellValue('${r['employee_type']}'),TextCellValue('${r['account_number']}'),TextCellValue('${r['ifsc']}'),DoubleCellValue(n(r['daily_rate'])),IntCellValue(n(r['month_days']).toInt()),DoubleCellValue(n(r['absent_days'])),DoubleCellValue(n(r['gross'])),DoubleCellValue(n(r['recovery'])),DoubleCellValue(n(r['net']))]);}
 final bytes=excel.encode();if(bytes==null)return;final dir=await getTemporaryDirectory();final f=File('${dir.path}/Lasalgaon_Daily_Wages_${y}_${m.toString().padLeft(2,'0')}.xlsx');await f.writeAsBytes(bytes,flush:true);await Share.shareXFiles([XFile(f.path)],text:'रोजंदार वेतन ${monthNames[m-1]} $y');
}
Future<void> _pdf(BuildContext c,int m,int y)async{final rows=await PayrollDb.instance.periodRows(m,y,activeOnly:true);final doc=pw.Document();doc.addPage(pw.MultiPage(build:(ctx)=>[pw.Header(level:0,child:pw.Text('Lasalgaon Gram Panchayat Payroll — $m/$y')),pw.Table.fromTextArray(headers:['No.','Name','Designation','Basic','Gross','Deductions','Net'],data:[for(var i=0;i<rows.length;i++)['${i+1}','${rows[i]['name_marathi']??''}','${rows[i]['designation']??''}','${n(rows[i]['basic']).toStringAsFixed(0)}','${n(rows[i]['gross']).toStringAsFixed(0)}','${n(rows[i]['deductions']).toStringAsFixed(0)}','${n(rows[i]['net']).toStringAsFixed(0)}']]) ]));await Printing.layoutPdf(onLayout:(_)=>doc.save());}
Future<void> _backup(BuildContext c)async{final dir=await getApplicationDocumentsDirectory();final file=File('${dir.path}/payroll.db');if(await file.exists())await Share.shareXFiles([XFile(file.path)],text:'Payroll database backup');else if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('डेटाबेस अद्याप तयार नाही')));}

}
class SettingsScreen extends StatefulWidget{const SettingsScreen({super.key});@override State<SettingsScreen> createState()=>_SettingsScreenState();}
class _SettingsScreenState extends State<SettingsScreen>{@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[Text('सेटिंग्ज',style:Theme.of(c).textTheme.headlineSmall),Card(child:ListTile(leading:const Icon(Icons.receipt_long),title:const Text('व्यवसाय कर सेटिंग'),subtitle:const Text('मर्यादा आणि कर रक्कम'),onTap:()=>_tax(c))),Card(child:ListTile(leading:const Icon(Icons.lock_reset),title:const Text('पासवर्ड बदला'),onTap:()=>_password(c))),Card(child:ListTile(leading:const Icon(Icons.event_available),title:const Text('पदानुसार निवृत्ती वय'),subtitle:const Text('डीफॉल्ट निवृत्ती वय 60 वर्षे'),onTap:()=>_retirement(c))),Card(child:ListTile(leading:const Icon(Icons.event),title:const Text('निवृत्ती वेळापत्रक'),subtitle:const Text('जन्मतारीख, निवृत्ती तारीख आणि उर्वरित दिवस'),onTap:()=>_retirementSchedule(c))),Card(child:ListTile(leading:const Icon(Icons.email_outlined),title:const Text('ईमेल अहवाल सेटिंग'),subtitle:const Text('प्राप्तकर्ता आणि स्वाक्षरी भूमिका जतन करा'),onTap:()=>_emailSettings(c))),Card(child:ListTile(leading:const Icon(Icons.upload_file),title:const Text('जुना डेटाबेस आयात'),subtitle:const Text('जुन्या payroll.db फाईलसाठी'),onTap:()=>_importDb(c))),const Padding(padding:EdgeInsets.all(12),child:Text('डेटा या Android डिव्हाइसवर स्थानिक SQLite डेटाबेसमध्ये साठवला जातो. भविष्यात multi-user वापरासाठी API/backend migration आवश्यक असेल.'))]);}
Future<void> _tax(BuildContext c)async{final tax=await PayrollDb.instance.taxSettings();final keys=['threshold','below_amount','above_amount','women_amount'];final labels=['मूळ वेतन मर्यादा','मर्यादेखाली कर','मर्यादेवर/वर कर','महिला कर्मचारी कर'];final cs={for(final k in keys)k:TextEditingController(text:'${tax[k]}')};if(!c.mounted)return;await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('व्यवसाय कर सेटिंग'),content:Column(mainAxisSize:MainAxisSize.min,children:[for(var i=0;i<keys.length;i++)TextField(controller:cs[keys[i]],keyboardType:TextInputType.number,decoration:InputDecoration(labelText:labels[i]))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{await PayrollDb.instance.saveTax({for(final k in keys)k:double.tryParse(cs[k]!.text)??0});if(c.mounted){Navigator.pop(d);setState((){});}},child:const Text('जतन करा'))]));}
Future<void> _password(BuildContext c)async{final old=TextEditingController(),next=TextEditingController(),confirm=TextEditingController();await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('पासवर्ड बदला'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:old,obscureText:true,decoration:const InputDecoration(labelText:'सध्याचा पासवर्ड')),TextField(controller:next,obscureText:true,decoration:const InputDecoration(labelText:'नवीन पासवर्ड')),TextField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'पुन्हा पासवर्ड'))]),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{if(!await PayrollDb.instance.verifyPassword(old.text)||next.text.length<8||next.text!=confirm.text){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('सध्याचा पासवर्ड तपासा. नवीन पासवर्ड किमान 8 अक्षरांचा आणि जुळणारा असावा.')));return;}await PayrollDb.instance.savePassword(next.text);if(c.mounted)Navigator.pop(d);},child:const Text('बदला'))]));}
Future<void> _retirement(BuildContext c)async{final rows=await PayrollDb.instance.employees(activeOnly:true);final saved=await PayrollDb.instance.retirementSettings();final names=<String>{...rows.map((r)=>'${r['designation']??''}').where((s)=>s.isNotEmpty),...saved.map((r)=>'${r['designation']??''}').where((s)=>s.isNotEmpty)}.toList()..sort();for(final name in names){final existing=await (await PayrollDb.instance.db).query('retirement_age_settings',where:'designation=?',whereArgs:[name]);final ctl=TextEditingController(text:existing.isEmpty?'60':'${existing.first['retirement_age']}');if(!c.mounted)return;await showDialog(context:c,builder:(d)=>AlertDialog(title:Text('$name — निवृत्ती वय'),content:TextField(controller:ctl,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'वय (वर्षे)')),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('बंद')),FilledButton(onPressed:()async{await (await PayrollDb.instance.db).insert('retirement_age_settings',{'designation':name,'retirement_age':int.tryParse(ctl.text)??60},conflictAlgorithm:ConflictAlgorithm.replace);if(c.mounted)Navigator.pop(d);},child:const Text('जतन करा'))]));}}
Future<void> _retirementSchedule(BuildContext c)async{
 final rows=await PayrollDb.instance.retirementSchedule(); if(!c.mounted)return;
 await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('निवृत्ती वेळापत्रक'),content:SizedBox(width:520,height:480,child:rows.isEmpty?const Center(child:Text('निवृत्ती वेळापत्रकासाठी कर्मचारी जन्मतारीख भरा.')):ListView.builder(itemCount:rows.length,itemBuilder:(ctx,i){final r=rows[i];return ListTile(leading:Icon(r['retired']==true?Icons.event_busy:Icons.event_available,color:r['retired']==true?Colors.red:Colors.green),title:Text('${r['name_marathi']??''}'),subtitle:Text('${r['designation']??''} • निवृत्ती: ${r['retirement_date']}'),trailing:SizedBox(width:90,child:Text(r['retired']==true?'निवृत्त':'${r['days_remaining']} दिवस',textAlign:TextAlign.end)));})),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('बंद'))]));
}
Future<void> _emailSettings(BuildContext c)async{
 final config=await PayrollDb.instance.emailSettings(); const secure=FlutterSecureStorage(); final savedSecret=await secure.read(key:'smtp_app_password')??''; final secret=TextEditingController(text:savedSecret); final from=TextEditingController(text:'${config['from_email']??''}'),to=TextEditingController(text:'${config['to_email']??''}'); String role='${config['signature_role']??'prashasak'}';
 if(!c.mounted)return;
 await showDialog(context:c,builder:(d)=>AlertDialog(title:const Text('ईमेल अहवाल सेटिंग'),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:from,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'पाठवणारा ईमेल')),TextField(controller:to,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'प्राप्तकर्ता ईमेल')),TextField(controller:secret,obscureText:true,decoration:const InputDecoration(labelText:'Gmail App Password')),DropdownButtonFormField<String>(value:role,decoration:const InputDecoration(labelText:'स्वाक्षरी भूमिका'),items:const [DropdownMenuItem(value:'prashasak',child:Text('प्रशासक')),DropdownMenuItem(value:'sarpanch',child:Text('सरपंच'))],onChanged:(v)=>role=v??'prashasak'),const SizedBox(height:8),const Text('Gmail मध्ये 2-Step Verification सुरू करून स्वतंत्र App Password वापरा. पासवर्ड Android secure storage मध्ये ठेवला जातो.',style:TextStyle(fontSize:12))])),actions:[TextButton(onPressed:()=>Navigator.pop(d),child:const Text('रद्द')),FilledButton(onPressed:()async{if(!from.text.trim().contains('@')||!to.text.trim().contains('@')){ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('वैध पाठवणारा आणि प्राप्तकर्ता ईमेल टाका.')));return;}await PayrollDb.instance.saveEmailSettings({'from_email':from.text.trim(),'to_email':to.text.trim(),'signature_role':role});if(secret.text.trim().isNotEmpty){await secure.write(key:'smtp_app_password',value:secret.text.trim());}if(c.mounted)Navigator.pop(d);},child:const Text('जतन करा'))]));
}
Future<void> _importDb(BuildContext c)async{final pick=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['db','sqlite','sqlite3'],withData:true);if(pick==null||pick.files.single.bytes==null)return;final bytes=pick.files.single.bytes!;if(bytes.length<16||String.fromCharCodes(bytes.take(15))!='SQLite format 3') {if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('ही वैध SQLite डेटाबेस फाईल नाही.')));return;}if(!c.mounted)return; final confirm=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('डेटाबेस आयात करा?'),content:const Text('सध्याच्या डेटाबेसचा .backup तयार होईल आणि निवडलेली फाईल सध्याचा डेटा बदलेल. पुढे सुरू ठेवायचे?'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('रद्द')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('आयात करा'))])); if(confirm!=true)return; try{await PayrollDb.instance.replaceDatabase(bytes);if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content:Text('डेटाबेस आयात झाला. कृपया अॅप पुन्हा उघडा.')));}catch(e){if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text('आयात अयशस्वी: $e')));}}
}