import 'package:flutter/material.dart';
import '../models/category.dart';
import '../database/database_helper.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}
class _CategoryManagerScreenState extends State<CategoryManagerScreen> {
  List<ActivityCategory> _categories = [];
  bool _isLoading = true;
  bool _showDisabled = false; // NEW: Toggle state

  final List<int> _palette = [
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 
    0xFF3F51B5, 0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 
    0xFF009688, 0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39, 
    0xFFFFEB3B, 0xFFFFC107, 0xFFFF9800, 0xFFFF5722, 
    0xFF795548, 0xFF9E9E9E, 0xFF607D8B, 0xFFD32F2F, 
    0xFFC2185B, 0xFF7B1FA2, 0xFF512DA8, 0xFF303F9F
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Fetch ALL, then filter in Dart based on our toggle
    final allCategories = await DatabaseHelper.instance.getAllCategories();
    if (mounted) {
      setState(() {
        _categories = allCategories.where((c) => c.isActive == !_showDisabled).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCategoryStatus(ActivityCategory category) async {
    // Flip the active status
    final updated = category.copyWith(isActive: !category.isActive);
    await DatabaseHelper.instance.updateCategory(updated);
    _loadCategories();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${category.name} ${updated.isActive ? 'Restored' : 'Archived'}.'),
          backgroundColor: Colors.white24,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCategorySheet({ActivityCategory? existingCategory}) {
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    int selectedColor = existingCategory != null ? existingCategory.colorVal : _palette.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    existingCategory == null ? 'NEW TAG' : 'EDIT TAG',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.deepPurpleAccent),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('COLOR', style: TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1.0)),
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 160,
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _palette.length,
                      itemBuilder: (context, index) {
                        final colorVal = _palette[index];
                        final isSelected = colorVal == selectedColor;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedColor = colorVal),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(colorVal),
                              shape: BoxShape.circle,
                              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                              boxShadow: isSelected 
                                  ? [BoxShadow(color: Color(colorVal).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)] 
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, foregroundColor: Colors.white),
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        if (existingCategory == null) {
                          final newCat = await DatabaseHelper.instance.getOrCreateCategory(name);
                          await DatabaseHelper.instance.updateCategory(newCat.copyWith(colorVal: selectedColor));
                        } else {
                          await DatabaseHelper.instance.updateCategory(
                            existingCategory.copyWith(name: name, colorVal: selectedColor)
                          );
                        }
                        
                        if (context.mounted) Navigator.pop(context, true);
                      },
                      child: const Text('SAVE CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    ).then((didSave) {
      if (didSave == true) _loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: Text(
          _showDisabled ? 'DISABLED TAGS' : 'ACTIVE TAGS', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            letterSpacing: 2.0,
            color: _showDisabled ? Colors.white54 : Colors.white,
          )
        ),
        centerTitle: true,
        actions: [
          // NEW: The Toggle Button
          IconButton(
            icon: Icon(_showDisabled ? Icons.visibility_off : Icons.visibility),
            color: _showDisabled ? Colors.redAccent : Colors.white54,
            onPressed: () {
              setState(() => _showDisabled = !_showDisabled);
              _loadCategories();
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _categories.isEmpty
              ? Center(child: Text(_showDisabled ? 'No disabled tags.' : 'No active tags.', style: const TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Dismissible(
                      key: Key('cat_${category.id}_${category.isActive}'),
                      direction: DismissDirection.endToStart,
                      // Dynamic background: Red for Archiving, Green for Restoring
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: _showDisabled ? Colors.green.withOpacity(0.8) : Colors.redAccent.withOpacity(0.8), 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Icon(_showDisabled ? Icons.restore : Icons.archive, color: Colors.white),
                      ),
                      onDismissed: (direction) => _toggleCategoryStatus(category),
                      child: Card(
                        color: const Color(0xFF252530),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          // NEW: Make the entire tile tappable!
                          onTap: () => _showCategorySheet(existingCategory: category),
                          leading: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Color(category.colorVal).withOpacity(_showDisabled ? 0.3 : 1.0), 
                              shape: BoxShape.circle
                            ),
                          ),
                          title: Text(
                            category.name, 
                            style: TextStyle(
                              fontWeight: FontWeight.bold, 
                              fontSize: 16,
                              color: _showDisabled ? Colors.white54 : Colors.white,
                              decoration: _showDisabled ? TextDecoration.lineThrough : null,
                            )
                          ),
                          // Changed from IconButton to just a static Icon since the whole row is clickable now
                          trailing: const Icon(Icons.edit_outlined, color: Colors.white30),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurpleAccent,
        onPressed: () => _showCategorySheet(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}