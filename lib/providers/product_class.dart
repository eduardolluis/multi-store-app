class Product {
  String name;
  double price;
  double salePrice;
  int qty;
  int quantity;
  List imagesUrl;
  String documentId;
  String supplierId;

  Product({
    required this.name,
    required this.price,
    required this.salePrice,
    required this.qty,
    required this.quantity,
    required this.imagesUrl,
    required this.documentId,
    required this.supplierId,
  });

  void increase() {
    qty++;
  }

  void decrease() {
    qty--;
  }
}
