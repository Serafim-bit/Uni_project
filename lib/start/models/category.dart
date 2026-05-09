class Category {
  const Category({ 
    required this.cat_text, 
    required this.imagePath,
    required this.id,
  });

  final String cat_text;
  final String imagePath; 
  final int id;
}

const CategoriesList = [
  Category(
    cat_text: 'Pomoc dla treningów', 
    imagePath: 'assets/images/trening_help.jpg', 
    id: 0
  ),
  Category(
    cat_text: 'Treningi', 
    imagePath: 'assets/images/photo.jpg', 
    id: 1
  ),
  Category(
    cat_text: 'Meals', 
    imagePath: 'assets/images/food.jpg', 
    id: 2
  ),
  Category(
    cat_text: 'Notatki', 
    imagePath: 'assets/images/notepad.jpg', 
    id: 3
  ),
];