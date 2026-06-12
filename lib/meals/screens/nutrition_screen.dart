import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uni_project/meals/database/meal_log_database_service.dart';
import 'package:uni_project/meals/models/category.dart';
import 'package:uni_project/meals/models/meal.dart';
import 'package:uni_project/meals/models/meal_entry.dart';
import 'package:uni_project/meals/services/meals_data_service.dart';
import 'package:uni_project/meals/widgets/meal_image.dart';

enum _RecipeTimeFilter { any, quick, standard, long }

String _formatComplexity(Complexity complexity) {
  return switch (complexity) {
    Complexity.simple => 'Simple',
    Complexity.challenging => 'Challenging',
    Complexity.hard => 'Hard',
  };
}

String _formatAffordability(Affordability affordability) {
  return switch (affordability) {
    Affordability.affordable => 'Affordable',
    Affordability.pricey => 'Pricey',
    Affordability.luxurious => 'Luxurious',
  };
}

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  List<MealEntry> _entries = [];
  List<Category> _recipeCategories = [];
  List<Meal> _recipes = [];
  Set<String> _favoriteRecipeIds = {};
  final TextEditingController _recipeSearchController = TextEditingController();
  bool _isLoading = true;
  int _selectedTab = 0;
  String _recipeSearchQuery = '';
  String? _selectedRecipeCategoryId;
  _RecipeTimeFilter _selectedTimeFilter = _RecipeTimeFilter.any;
  Complexity? _selectedComplexity;
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _recipeSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final entries = await MealLogDatabaseService.instance.getEntries();
    final categories = await DataService.loadCategories();
    final recipes = await DataService.loadMeals();
    final favoriteRecipeIds = await MealLogDatabaseService.instance
        .getFavoriteRecipeIds();
    if (!mounted) return;

    setState(() {
      _entries = entries;
      _recipeCategories = categories;
      _recipes = recipes;
      _favoriteRecipeIds = favoriteRecipeIds;
      _isLoading = false;
    });
  }

  List<MealEntry> get _todayEntries {
    final now = DateTime.now();
    return _entries
        .where(
          (entry) =>
              entry.date.year == now.year &&
              entry.date.month == now.month &&
              entry.date.day == now.day,
        )
        .toList();
  }

  int get _todayCalories {
    return _todayEntries.fold(0, (sum, entry) => sum + (entry.calories ?? 0));
  }

  int get _todayProtein {
    return _todayEntries.fold(0, (sum, entry) => sum + (entry.protein ?? 0));
  }

  List<Meal> get _filteredRecipes {
    final query = _recipeSearchQuery.trim().toLowerCase();

    return _recipes.where((recipe) {
      final matchesQuery =
          query.isEmpty ||
          recipe.title.toLowerCase().contains(query) ||
          recipe.ingredients.any(
            (ingredient) => ingredient.toLowerCase().contains(query),
          );
      final matchesCategory =
          _selectedRecipeCategoryId == null ||
          recipe.categories.contains(_selectedRecipeCategoryId);
      final matchesTime = switch (_selectedTimeFilter) {
        _RecipeTimeFilter.any => true,
        _RecipeTimeFilter.quick => recipe.duration <= 20,
        _RecipeTimeFilter.standard =>
          recipe.duration > 20 && recipe.duration <= 35,
        _RecipeTimeFilter.long => recipe.duration > 35,
      };
      final matchesComplexity =
          _selectedComplexity == null ||
          recipe.complexity == _selectedComplexity;
      final matchesFavorite =
          !_showFavoritesOnly || _favoriteRecipeIds.contains(recipe.id);

      return matchesQuery &&
          matchesCategory &&
          matchesTime &&
          matchesComplexity &&
          matchesFavorite;
    }).toList();
  }

  Future<void> _saveEntry(_MealEntryFormData data) async {
    final entry = MealEntry(
      id: data.id,
      date: data.date,
      type: data.type,
      title: data.title,
      calories: data.calories,
      protein: data.protein,
      notes: data.notes,
    );

    if (entry.id == null) {
      await MealLogDatabaseService.instance.insertEntry(entry);
    } else {
      await MealLogDatabaseService.instance.updateEntry(entry);
    }
  }

  Future<void> _openEntrySheet({MealEntry? entry}) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MealEntrySheet(entry: entry, onSave: _saveEntry),
    );

    if (didSave == true) {
      await _loadData();
    }
  }

  Future<void> _deleteEntry(MealEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete meal?'),
        content: const Text('This meal entry will be removed from your log.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || entry.id == null) return;

    await MealLogDatabaseService.instance.deleteEntry(entry.id!);
    await _loadData();
  }

  Future<void> _toggleFavoriteRecipe(Meal recipe) async {
    final isFavorite = _favoriteRecipeIds.contains(recipe.id);
    await MealLogDatabaseService.instance.setFavoriteRecipe(
      recipe.id,
      !isFavorite,
    );

    if (!mounted) return;

    setState(() {
      if (isFavorite) {
        _favoriteRecipeIds.remove(recipe.id);
      } else {
        _favoriteRecipeIds.add(recipe.id);
      }
    });
  }

  Future<void> _addRecipeToMealLog(Meal recipe) async {
    await MealLogDatabaseService.instance.insertEntry(
      MealEntry(
        date: DateTime.now(),
        type: 'Recipe',
        title: recipe.title,
        calories: null,
        protein: null,
        notes:
            'Recipe from guide • ${recipe.duration} min • ${_formatComplexity(recipe.complexity)}',
      ),
    );

    await _loadData();

    if (!mounted) return;

    setState(() => _selectedTab = 0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${recipe.title} added to Meal Log')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              cacheExtent: 1200,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(
                    children: [
                      _NutritionHeader(
                        todayCalories: _todayCalories,
                        todayProtein: _todayProtein,
                        mealCount: _todayEntries.length,
                      ),
                      const SizedBox(height: 14),
                      _NutritionTabs(
                        selectedIndex: _selectedTab,
                        onChanged: (index) {
                          setState(() => _selectedTab = index);
                        },
                      ),
                      const SizedBox(height: 14),
                    ],
                  ),
                ),
                if (_selectedTab == 0)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    sliver: SliverToBoxAdapter(
                      child: _MealLogTab(
                        entries: _entries,
                        onAdd: () => _openEntrySheet(),
                        onEdit: (entry) => _openEntrySheet(entry: entry),
                        onDelete: _deleteEntry,
                      ),
                    ),
                  )
                else
                  _RecipeGuideTab(
                    categories: _recipeCategories,
                    recipes: _filteredRecipes,
                    favoriteRecipeIds: _favoriteRecipeIds,
                    searchController: _recipeSearchController,
                    searchQuery: _recipeSearchQuery,
                    selectedCategoryId: _selectedRecipeCategoryId,
                    selectedTimeFilter: _selectedTimeFilter,
                    selectedComplexity: _selectedComplexity,
                    showFavoritesOnly: _showFavoritesOnly,
                    onSearchChanged: (value) {
                      setState(() => _recipeSearchQuery = value);
                    },
                    onSelectCategory: (categoryId) {
                      setState(() => _selectedRecipeCategoryId = categoryId);
                    },
                    onSelectTimeFilter: (filter) {
                      setState(() => _selectedTimeFilter = filter);
                    },
                    onSelectComplexity: (complexity) {
                      setState(() => _selectedComplexity = complexity);
                    },
                    onToggleFavoritesOnly: () {
                      setState(() => _showFavoritesOnly = !_showFavoritesOnly);
                    },
                    onToggleFavorite: _toggleFavoriteRecipe,
                    onAddRecipe: _addRecipeToMealLog,
                  ),
              ],
            ),
      floatingActionButton: _selectedTab == 0
          ? FloatingActionButton(
              onPressed: () => _openEntrySheet(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

class _NutritionHeader extends StatelessWidget {
  const _NutritionHeader({
    required this.todayCalories,
    required this.todayProtein,
    required this.mealCount,
  });

  final int todayCalories;
  final int todayProtein;
  final int mealCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today nutrition',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _NutritionStatTile(
                    icon: Icons.local_fire_department_outlined,
                    label: 'Calories',
                    value: todayCalories == 0 ? '-' : todayCalories.toString(),
                    helper: 'kcal',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionStatTile(
                    icon: Icons.egg_alt_outlined,
                    label: 'Protein',
                    value: todayProtein == 0 ? '-' : todayProtein.toString(),
                    helper: 'grams',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionStatTile(
                    icon: Icons.restaurant_menu,
                    label: 'Meals',
                    value: mealCount.toString(),
                    helper: 'today',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionStatTile extends StatelessWidget {
  const _NutritionStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionTabs extends StatelessWidget {
  const _NutritionTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(
          value: 0,
          icon: Icon(Icons.edit_note),
          label: Text('Meal Log'),
        ),
        ButtonSegment(
          value: 1,
          icon: Icon(Icons.menu_book_outlined),
          label: Text('Recipes'),
        ),
      ],
      selected: {selectedIndex},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _MealLogTab extends StatelessWidget {
  const _MealLogTab({
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final List<MealEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<MealEntry> onEdit;
  final ValueChanged<MealEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return _EmptyMealLogState(onAdd: onAdd);
    }

    return Column(
      children: [
        for (final entry in entries)
          _MealEntryCard(
            entry: entry,
            onEdit: () => onEdit(entry),
            onDelete: () => onDelete(entry),
          ),
      ],
    );
  }
}

class _EmptyMealLogState extends StatelessWidget {
  const _EmptyMealLogState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.restaurant,
                size: 34,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged yet',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Add meals with calories, protein, and quick notes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Meal'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final MealEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${entry.type} • ${DateFormat('d MMM').format(entry.date)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MealChip(
                          icon: Icons.local_fire_department_outlined,
                          label: entry.caloriesLabel,
                        ),
                        _MealChip(
                          icon: Icons.egg_alt_outlined,
                          label: entry.proteinLabel,
                        ),
                      ],
                    ),
                    if (entry.notes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        entry.notes,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    tooltip: 'Edit meal',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    tooltip: 'Delete meal',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealChip extends StatelessWidget {
  const _MealChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeGuideTab extends StatelessWidget {
  const _RecipeGuideTab({
    required this.categories,
    required this.recipes,
    required this.favoriteRecipeIds,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.selectedTimeFilter,
    required this.selectedComplexity,
    required this.showFavoritesOnly,
    required this.onSearchChanged,
    required this.onSelectCategory,
    required this.onSelectTimeFilter,
    required this.onSelectComplexity,
    required this.onToggleFavoritesOnly,
    required this.onToggleFavorite,
    required this.onAddRecipe,
  });

  final List<Category> categories;
  final List<Meal> recipes;
  final Set<String> favoriteRecipeIds;
  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategoryId;
  final _RecipeTimeFilter selectedTimeFilter;
  final Complexity? selectedComplexity;
  final bool showFavoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<_RecipeTimeFilter> onSelectTimeFilter;
  final ValueChanged<Complexity?> onSelectComplexity;
  final VoidCallback onToggleFavoritesOnly;
  final ValueChanged<Meal> onToggleFavorite;
  final ValueChanged<Meal> onAddRecipe;

  @override
  Widget build(BuildContext context) {
    return SliverMainAxisGroup(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          sliver: SliverToBoxAdapter(
            child: _RecipeFilterPanel(
              categories: categories,
              searchController: searchController,
              searchQuery: searchQuery,
              selectedCategoryId: selectedCategoryId,
              selectedTimeFilter: selectedTimeFilter,
              selectedComplexity: selectedComplexity,
              showFavoritesOnly: showFavoritesOnly,
              onSearchChanged: onSearchChanged,
              onSelectCategory: onSelectCategory,
              onSelectTimeFilter: onSelectTimeFilter,
              onSelectComplexity: onSelectComplexity,
              onToggleFavoritesOnly: onToggleFavoritesOnly,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          sliver: SliverToBoxAdapter(
            child: _RecipeResultHeader(count: recipes.length),
          ),
        ),
        if (recipes.isEmpty)
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 88),
            sliver: SliverToBoxAdapter(child: _EmptyRecipeState()),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
            sliver: SliverList.builder(
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _RecipeCard(
                  recipe: recipe,
                  isFavorite: favoriteRecipeIds.contains(recipe.id),
                  onToggleFavorite: () => onToggleFavorite(recipe),
                  onAdd: () => onAddRecipe(recipe),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RecipeFilterPanel extends StatelessWidget {
  const _RecipeFilterPanel({
    required this.categories,
    required this.searchController,
    required this.searchQuery,
    required this.selectedCategoryId,
    required this.selectedTimeFilter,
    required this.selectedComplexity,
    required this.showFavoritesOnly,
    required this.onSearchChanged,
    required this.onSelectCategory,
    required this.onSelectTimeFilter,
    required this.onSelectComplexity,
    required this.onToggleFavoritesOnly,
  });

  final List<Category> categories;
  final TextEditingController searchController;
  final String searchQuery;
  final String? selectedCategoryId;
  final _RecipeTimeFilter selectedTimeFilter;
  final Complexity? selectedComplexity;
  final bool showFavoritesOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onSelectCategory;
  final ValueChanged<_RecipeTimeFilter> onSelectTimeFilter;
  final ValueChanged<Complexity?> onSelectComplexity;
  final VoidCallback onToggleFavoritesOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              labelText: 'Search recipes',
              hintText: 'Pasta, salmon, breakfast...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _FilterSection(
            title: 'Category',
            children: [
              _RecipeChoiceChip(
                label: 'All',
                selected: selectedCategoryId == null,
                onTap: () => onSelectCategory(null),
              ),
              for (final category in categories)
                _RecipeChoiceChip(
                  label: category.title,
                  selected: selectedCategoryId == category.id,
                  onTap: () => onSelectCategory(category.id),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Time',
            children: [
              _RecipeChoiceChip(
                label: 'Any',
                selected: selectedTimeFilter == _RecipeTimeFilter.any,
                onTap: () => onSelectTimeFilter(_RecipeTimeFilter.any),
              ),
              _RecipeChoiceChip(
                label: '<= 20 min',
                selected: selectedTimeFilter == _RecipeTimeFilter.quick,
                onTap: () => onSelectTimeFilter(_RecipeTimeFilter.quick),
              ),
              _RecipeChoiceChip(
                label: '21-35 min',
                selected: selectedTimeFilter == _RecipeTimeFilter.standard,
                onTap: () => onSelectTimeFilter(_RecipeTimeFilter.standard),
              ),
              _RecipeChoiceChip(
                label: '36+ min',
                selected: selectedTimeFilter == _RecipeTimeFilter.long,
                onTap: () => onSelectTimeFilter(_RecipeTimeFilter.long),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterSection(
            title: 'Difficulty',
            children: [
              _RecipeChoiceChip(
                label: 'Any',
                selected: selectedComplexity == null,
                onTap: () => onSelectComplexity(null),
              ),
              for (final complexity in Complexity.values)
                _RecipeChoiceChip(
                  label: _formatComplexity(complexity),
                  selected: selectedComplexity == complexity,
                  onTap: () => onSelectComplexity(complexity),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              selected: showFavoritesOnly,
              avatar: Icon(
                showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                size: 18,
              ),
              label: const Text('Favorites only'),
              onSelected: (_) => onToggleFavoritesOnly(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _RecipeChoiceChip extends StatelessWidget {
  const _RecipeChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) => onTap(),
    );
  }
}

class _RecipeResultHeader extends StatelessWidget {
  const _RecipeResultHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Recipes',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          '$count found',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyRecipeState extends StatelessWidget {
  const _EmptyRecipeState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'No recipes found',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another category, time range, or search term.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({
    required this.recipe,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onAdd,
  });

  final Meal recipe;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              MealImage(
                imagePath: recipe.imageUrl,
                height: 172,
                cacheWidth: 900,
                cacheHeight: 480,
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton.filledTonal(
                  tooltip: isFavorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MealChip(
                      icon: Icons.schedule,
                      label: '${recipe.duration} min',
                    ),
                    _MealChip(
                      icon: Icons.speed_outlined,
                      label: _formatComplexity(recipe.complexity),
                    ),
                    _MealChip(
                      icon: Icons.attach_money,
                      label: _formatAffordability(recipe.affordability),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Meal Log'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MealEntrySheet extends StatefulWidget {
  const _MealEntrySheet({required this.entry, required this.onSave});

  final MealEntry? entry;
  final Future<void> Function(_MealEntryFormData data) onSave;

  @override
  State<_MealEntrySheet> createState() => _MealEntrySheetState();
}

class _MealEntrySheetState extends State<_MealEntrySheet> {
  static const _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  late final TextEditingController _titleController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late String _selectedType;
  bool _isSaving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;

    _titleController = TextEditingController(text: entry?.title ?? '');
    _caloriesController = TextEditingController(
      text: entry?.calories == null ? '' : entry!.calories.toString(),
    );
    _proteinController = TextEditingController(
      text: entry?.protein == null ? '' : entry!.protein.toString(),
    );
    _notesController = TextEditingController(text: entry?.notes ?? '');
    _selectedDate = entry?.date ?? DateTime.now();
    _selectedType = entry?.type ?? 'Breakfast';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;

    setState(() => _selectedDate = pickedDate);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add a meal name first.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await widget.onSave(
        _MealEntryFormData(
          id: widget.entry?.id,
          date: _selectedDate,
          type: _selectedType,
          title: title,
          calories: int.tryParse(_caloriesController.text.trim()),
          protein: int.tryParse(_proteinController.text.trim()),
          notes: _notesController.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save this meal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _isEditing ? 'Edit Meal' : 'Add Meal',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Track calories, protein, and quick notes.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    DateFormat('EEE, d MMM yyyy').format(_selectedDate),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Meal type',
                    prefixIcon: Icon(Icons.restaurant_menu),
                  ),
                  items: [
                    for (final type in _mealTypes)
                      DropdownMenuItem(value: type, child: Text(type)),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Meal name',
                    hintText: 'Chicken bowl',
                    prefixIcon: Icon(Icons.lunch_dining),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          suffixText: 'kcal',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _proteinController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Protein',
                          suffixText: 'g',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    hintText: 'How it fit your day...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: Text(_isSaving ? 'Saving...' : 'Save Meal'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MealEntryFormData {
  const _MealEntryFormData({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.calories,
    required this.protein,
    required this.notes,
  });

  final int? id;
  final DateTime date;
  final String type;
  final String title;
  final int? calories;
  final int? protein;
  final String notes;
}
