import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Database _database;
  List<Map<String, dynamic>> _products = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      p.join(await getDatabasesPath(), 'products_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE products(id INTEGER PRIMARY KEY, name TEXT, brand TEXT, weight REAL, price REAL, productionDate TEXT, expirationDate TEXT, quantity INTEGER)',
        );
      },
      version: 1,
    );
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    final List<Map<String, dynamic>> products = await _database.query('products');
    setState(() {
      _products = products;
    });
  }

  Future<void> _addProduct(Map<String, dynamic> product) async {
    await _database.insert(
      'products',
      product,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _fetchProducts();
  }

  Future<void> _updateProduct(Map<String, dynamic> product) async {
    await _database.update(
      'products',
      product,
      where: 'id = ?',
      whereArgs: [product['id']],
    );
    _fetchProducts();
  }

  Future<void> _deleteProduct(int id) async {
    await _database.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    _fetchProducts();
  }

  Future<void> _searchProducts(String query) async {
    final List<Map<String, dynamic>> products = await _database.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    setState(() {
      _products = products;
    });
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    final TextEditingController nameController = TextEditingController(
        text: product != null ? product['name'] : '');
    final TextEditingController brandController = TextEditingController(
        text: product != null ? product['brand'] : '');
    final TextEditingController weightController = TextEditingController(
        text: product != null ? product['weight'].toString() : '');
    final TextEditingController priceController = TextEditingController(
        text: product != null ? product['price'].toString() : '');
    final TextEditingController productionDateController =
    TextEditingController(
        text: product != null ? product['productionDate'] : '');
    final TextEditingController expirationDateController =
    TextEditingController(
        text: product != null ? product['expirationDate'] : '');
    final TextEditingController quantityController = TextEditingController(
        text: product != null ? product['quantity'].toString() : '');

    showDialog(
      context: context,
      builder: (BuildContext contextDialog) {
        return AlertDialog(
          title: Text(product != null ? 'تعديل المنتج' : 'إضافة منتج'),
          content: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'اسم المنتج'),
                ),
                TextField(
                  controller: brandController,
                  decoration: InputDecoration(labelText: 'اسم العلامة التجارية'),
                ),
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(labelText: 'الوزن'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: 'السعر'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: productionDateController,
                  decoration: InputDecoration(labelText: 'تاريخ الإنتاج'),
                ),
                TextField(
                  controller: expirationDateController,
                  decoration: InputDecoration(labelText: 'تاريخ الانتهاء'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: InputDecoration(labelText: 'عدد القطع المتوافرة'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('إلغاء'),
              onPressed: () {
                Navigator.of(contextDialog).pop();
              },
            ),
            TextButton(
              child: Text(product != null ? 'تعديل' : 'إضافة'),
              onPressed: () {
                final Map<String, dynamic> newProduct = {
                  'name': nameController.text,
                  'brand': brandController.text,
                  'weight': double.tryParse(weightController.text) ?? 0.0,
                  'price': double.tryParse(priceController.text) ?? 0.0,
                  'productionDate': productionDateController.text,
                  'expirationDate': expirationDateController.text,
                  'quantity': int.tryParse(quantityController.text) ?? 0,
                };
                if (product != null) {
                  newProduct['id'] = product['id'];
                  _updateProduct(newProduct);
                } else {
                  _addProduct(newProduct);
                }
                Navigator.of(contextDialog).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    // تنفيذ عملية تسجيل الخروج
    Navigator.of(context).pop(); // العودة إلى الصفحة السابقة أو تسجيل الخروج
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            iconSize: 40.0, // يمكنك تعديل الحجم هنا

            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.purpleAccent,
              Colors.purple,
              Colors.purple,
            ],
          ),
        ),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'بحث عن منتج',
                  filled: true,
                  fillColor: Colors.grey[200], // لون لؤلؤي
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      _searchProducts(_searchController.text);
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                    padding: EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              product['name'],
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text('العلامة التجارية: ${product['brand']}'),

                            Text('السعر: ${product['price']}'),

                          ],
                        ),
                        Row(
                          children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _showProductForm(product: product);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteProduct(product['id']);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  _showProductForm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('إضافة منتج جديد', style: TextStyle(fontSize: 25)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
