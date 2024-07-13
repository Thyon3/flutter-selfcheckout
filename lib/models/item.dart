class Item {
  String name;
  String barcode;
  double price;
  double weight;
  int quantity;
  String? photo;
  String? category;
  String? description;
  DateTime? addedDate;

  Item({
    required this.name,
    required this.barcode,
    required this.price,
    required this.weight,
    required this.quantity,
    this.photo,
    this.category,
    this.description,
    this.addedDate,
  });

  // Constructor for creating from Firestore data
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      name: map['name'] ?? '',
      barcode: map['barcode'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      weight: (map['weight'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 1,
      photo: map['photo'],
      category: map['category'],
      description: map['description'],
      addedDate: map['addedDate'] != null 
          ? (map['addedDate'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'weight': weight,
      'quantity': quantity,
      'photo': photo,
      'category': category,
      'description': description,
      'addedDate': addedDate != null 
          ? Timestamp.fromDate(addedDate!) 
          : null,
    };
  }

  // Calculate total price for this item
  double get totalPrice => price * quantity;

  // Calculate total weight for this item
  double get totalWeight => weight * quantity;

  // Create a copy with updated quantity
  Item copyWith({int? quantity}) {
    return Item(
      name: name,
      barcode: barcode,
      price: price,
      weight: weight,
      quantity: quantity ?? this.quantity,
      photo: photo,
      category: category,
      description: description,
      addedDate: addedDate,
    );
  }

  @override
  String toString() {
    return 'Item(name: $name, barcode: $barcode, price: $price, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && 
           other.name == name && 
           other.barcode == barcode &&
           other.price == price;
  }

  @override
  int get hashCode {
    return name.hashCode ^ barcode.hashCode ^ price.hashCode;
  }
}
