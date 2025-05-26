import 'package:flutter/material.dart';
import 'supabase_service.dart'; // must define VaultItem and fetchVaultItems()
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ArtVault extends StatefulWidget {
  const ArtVault({super.key});

  @override
  ArtVaultState createState() => ArtVaultState();
}

class ArtVaultState extends State<ArtVault> {
  late Future<List<VaultItem>> _vaultItemsFuture;
  late Future<String?> _usernameFuture;
  // Keep track of item quantities by their unique ID
  final Map<String, int> quantities = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    try {
      final itemsFuture = SupabaseService.fetchVaultItems();
      final usernameFuture = _getCurrentUsername();
      
      // Wait for both futures to complete
      final results = await Future.wait([itemsFuture, usernameFuture]);
      
      if (mounted) {
        setState(() {
          _vaultItemsFuture = Future.value(results[0] as List<VaultItem>);
          _usernameFuture = Future.value(results[1] as String?);
        });
      }
    } catch (e) {
      print('Error loading vault data: $e');
      if (mounted) {
        // Reinitialize with error state
        setState(() {
          _vaultItemsFuture = SupabaseService.fetchVaultItems();
          _usernameFuture = _getCurrentUsername();
        });
      }
    }
  }

  Future<String?> _getCurrentUsername() async {
    try {
      final currentUser = SupabaseService.supabase.auth.currentUser;
      if (currentUser == null) return null;
      
      final userData = await SupabaseService.supabase
          .from('users')
          .select('username')
          .eq('user_id', currentUser.id)
          .single();
          
      return userData['username'] as String?;
    } catch (e) {
      print('Error getting username: $e');
      return null;
    }
  }

  Future<void> _onQuantityChanged(String itemId, int newQuantity) async {
    if (newQuantity < 1) return; // Don't allow quantities less than 1
    
    setState(() {
      quantities[itemId] = newQuantity;
    });
    
    // Update quantity in the database
    final success = await SupabaseService.updateVaultItemQuantity(itemId, newQuantity);
    if (!success) {
      // Revert the UI change if the update fails
      if (mounted) {
        setState(() {
          quantities.remove(itemId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff14c1e1),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Art Vault',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter-Bold',
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Add edit functionality here
            },
            child: const Text(
              'Edit',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontFamily: 'Inter-Regular',
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<VaultItem>>(
        future: _vaultItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No items in your vault.'));
          }

          final items = snapshot.data!;
          return FutureBuilder<String?>(
            future: _usernameFuture,
            builder: (context, usernameSnapshot) {
              if (usernameSnapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final username = usernameSnapshot.hasData ? usernameSnapshot.data! : 'User';
              
              return SingleChildScrollView(
                child: Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    // Create a unique key for the item
                    final itemId = '${item.userId}_${item.productName}_${item.variation ?? ''}';
                    // Use the quantity from our local state if available, otherwise use the item's quantity
                    final quantity = quantities[itemId] ?? item.quantity;

                    return _buildCart(
                      username: username,
                      productname: item.productName,
                      variation: item.variation ?? '',
                      quantity: quantity,
                      price: item.price,
                      iconPath: item.iconUrl,
                      imagePath: item.imageUrl,
                      onQuantityChanged: (newQty) => _onQuantityChanged(itemId, newQty),
                      useNetworkImages: true,
                    );
                  }),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home_outlined, size: 28),
              onPressed: () => Navigator.pushNamed(context, "/home"),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.pin, size: 28),
              onPressed: () => Navigator.pushNamed(context, "/pinboards"),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xff14c1e1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
              onPressed: () => Navigator.pushNamed(context, "/createpost"),
            ),
            IconButton(
              icon: const Icon(LucideIcons.vault, size: 28, color: Color(0xff14c1e1)),
              onPressed: () => Navigator.pushReplacementNamed(context, "/vault"),
            ),
            IconButton(
              icon: const Icon(Icons.person_outline, size: 28),
              onPressed: () => Navigator.pushNamed(context, "/profile"),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildCart({
  required String username,
  required String productname,
  required String variation,
  required int quantity,
  required double price,
  required String iconPath,
  required String imagePath,
  required ValueChanged<int> onQuantityChanged,
  bool useNetworkImages = false, // add flag to decide image type
}) {
  return Container(
    color: Colors.white,
    child: SizedBox(
      width: 393,
      height: 132,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            child: SizedBox(
              width: 393,
              height: 42,
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  CircleAvatar(
                    radius: 13,
                    backgroundImage: useNetworkImages
                        ? NetworkImage(iconPath)
                        : AssetImage(iconPath) as ImageProvider,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xff30343d),
                      fontFamily: 'Inter-Regular',
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Color(0xffea1a7f)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 6.999,
            width: 380,
            top: 42.492,
            height: 1,
            child: Container(
              width: 380,
              height: 1,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffea1a7f), width: 2),
              ),
            ),
          ),
          Positioned(
            left: 0,
            width: 393,
            top: 46,
            height: 80,
            child: Stack(
              children: [
                Container(
                  width: 393,
                  height: 80,
                  color: const Color(0xfffffdfd),
                ),
                Positioned(
                  left: 23,
                  top: 32,
                  child: Container(
                    width: 17,
                    height: 17,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffbdbec0), width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Positioned(
                  left: 53,
                  top: 7,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: useNetworkImages
                        ? Image.network(
                            imagePath,
                            width: 65,
                            height: 66.182,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            imagePath,
                            width: 65,
                            height: 66.182,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  left: 131,
                  top: 9,
                  child: Text(
                    productname,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xff7d7e7f),
                      fontFamily: 'Inter-Regular',
                    ),
                  ),
                ),
                Positioned(
                  left: 294,
                  top: 49,
                  child: Text(
                    '₱${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xffea1a7f),
                      fontFamily: 'Inter-Bold',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                QuantitySelector(
                  quantity: quantity,
                  onQuantityChanged: onQuantityChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onQuantityChanged;

  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 131,
      top: 30,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xffd9d9d9), width: 1.5),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (quantity > 1) {
                  onQuantityChanged(quantity - 1);
                }
              },
              child: const SizedBox(
                width: 17,
                height: 17,
                child: Icon(Icons.remove, size: 14),
              ),
            ),
            Container(
              width: 17,
              height: 17,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffd9d9d9), width: 1),
              ),
              child: Text(
                quantity.toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
            GestureDetector(
              onTap: () {
                onQuantityChanged(quantity + 1);
              },
              child: const SizedBox(
                width: 17,
                height: 17,
                child: Icon(Icons.add, size: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
