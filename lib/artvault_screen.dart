import 'package:flutter/material.dart';
import 'api_service.dart'; // must define VaultItem and fetchVaultItems()
import 'package:flutter/cupertino.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ArtVault extends StatefulWidget {
  const ArtVault({super.key});

  @override
  ArtVaultState createState() => ArtVaultState();
}

class ArtVaultState extends State<ArtVault> {
  late Future<List<VaultItem>> _vaultItemsFuture;
  // Keep quantity per item by index
  final Map<int, int> quantities = {};

  @override
  void initState() {
    super.initState();
    _vaultItemsFuture = ApiService.fetchVaultItems();
  }

  void _onQuantityChanged(int index, int newQuantity) {
    setState(() {
      quantities[index] = newQuantity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const TopBar(),
        automaticallyImplyLeading: false,
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
          return SingleChildScrollView(
            child: Column(
              children: List.generate(items.length, (index) {
                final item = items[index];
                final quantity = quantities[index] ?? item.quantity;

                return _buildCart(
                  username: item.username,
                  productname: item.productname,
                  variation: item.variation,
                  quantity: quantity,
                  price: item.price,
                  iconPath: item.iconUrl, // Assuming this is a network URL
                  imagePath: item.imageUrl, // Assuming this is a network URL
                  onQuantityChanged: (newQty) => _onQuantityChanged(index, newQty),
                  useNetworkImages: true,
                );
              }),
            ),
          );
        },
      ),
      bottomNavigationBar: Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.5 * 255).round()),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () {
                      Navigator.pushNamed(context, "/home");
                    },
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.pin),
                    onPressed: () {
                      Navigator.pushNamed(context, "/pinboards");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box_outlined),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.vault),
                    color: const Color.fromRGBO(20, 193, 225, 100),
                    onPressed: () {
                      Navigator.pushNamed(context, "/vault");
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () {
                      Navigator.pushNamed(context, "/profile");
                    },
                  ),
                ],
              ),
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

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xff14c1e1),
      child: SizedBox(
        width: double.infinity,
        height: 76,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              width: double.infinity,
              top: 0,
              height: 76,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xff14c1e1),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 15,
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, "/homescreen");
                        },
                      ),
                    ),
                    const Positioned(
                      left: 39,
                      top: 27,
                      child: Text(
                        'Art Vault',
                        style: TextStyle(
                          fontSize: 20,
                          color: Color(0xff000000),
                          fontFamily: 'Inter-Bold',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 330,
                      top: 30,
                      child: Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xff000000),
                          fontFamily: 'Inter-Regular',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
