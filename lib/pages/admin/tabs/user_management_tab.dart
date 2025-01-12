import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class UserManagementTab extends StatefulWidget {
  const UserManagementTab({super.key});

  @override
  State<UserManagementTab> createState() => _UserManagementTabState();
}

class _UserManagementTabState extends State<UserManagementTab> {
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'name'; // Default sort
  bool _sortAscending = true;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, dynamic>> _sortUsers(
      List<MapEntry<String, dynamic>> users) {
    switch (_sortBy) {
      case 'name':
        users.sort((a, b) => _sortAscending
            ? (a.value['name'] ?? '').compareTo(b.value['name'] ?? '')
            : (b.value['name'] ?? '').compareTo(a.value['name'] ?? ''));
        break;
      case 'email':
        users.sort((a, b) => _sortAscending
            ? (a.value['email'] ?? '').compareTo(b.value['email'] ?? '')
            : (b.value['email'] ?? '').compareTo(a.value['email'] ?? ''));
        break;
      case 'status':
        users.sort((a, b) {
          final aStatus = a.value['disabled'] == true;
          final bStatus = b.value['disabled'] == true;
          return _sortAscending
              ? aStatus.toString().compareTo(bStatus.toString())
              : bStatus.toString().compareTo(aStatus.toString());
        });
        break;
      case 'lastLogin':
        users.sort((a, b) {
          final aLogin = a.value['lastLogin'] ?? 0;
          final bLogin = b.value['lastLogin'] ?? 0;
          return _sortAscending
              ? aLogin.compareTo(bLogin)
              : bLogin.compareTo(aLogin);
        });
        break;
    }
    return users;
  }

  List<MapEntry<String, dynamic>> _filterUsers(
      List<MapEntry<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((entry) {
      final userData = entry.value as Map<dynamic, dynamic>;
      final name = (userData['name'] ?? '').toString().toLowerCase();
      final email = (userData['email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              // Sort Options
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Sort by: '),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Name'),
                      selected: _sortBy == 'name',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (_sortBy == 'name') {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = 'name';
                              _sortAscending = true;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Email'),
                      selected: _sortBy == 'email',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (_sortBy == 'email') {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = 'email';
                              _sortAscending = true;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Status'),
                      selected: _sortBy == 'status',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (_sortBy == 'status') {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = 'status';
                              _sortAscending = true;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Last Login'),
                      selected: _sortBy == 'lastLogin',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            if (_sortBy == 'lastLogin') {
                              _sortAscending = !_sortAscending;
                            } else {
                              _sortBy = 'lastLogin';
                              _sortAscending = true;
                            }
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseDatabase.instance.ref().child('users').onValue,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data?.snapshot?.value == null) {
                return const Center(child: Text('No users found'));
              }

              Map<dynamic, dynamic> allUsers =
                  snapshot.data!.snapshot!.value as Map;

              // Filter out admin users and cast to correct type
              var users = allUsers.entries
                  .where((entry) => (entry.value as Map)['role'] != 'admin')
                  .map((entry) => MapEntry<String, dynamic>(
                        entry.key.toString(),
                        entry.value as Map<dynamic, dynamic>,
                      ))
                  .toList();

              // Apply search filter
              users = _filterUsers(users);

              // Apply sorting
              users = _sortUsers(users);

              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  String userId = users[index].key;
                  Map<dynamic, dynamic> userData = users[index].value as Map;
                  bool isDisabled = userData['disabled'] == true;

                  // Format address if it exists
                  String formattedAddress = '';
                  if (userData['address'] != null) {
                    final address = userData['address'] as Map;
                    final List<String> addressParts = [];

                    if (address['line1']?.toString().isNotEmpty == true) {
                      addressParts.add(address['line1'].toString());
                    }
                    if (address['line2']?.toString().isNotEmpty == true) {
                      addressParts.add(address['line2'].toString());
                    }
                    if (address['city']?.toString().isNotEmpty == true) {
                      addressParts.add(address['city'].toString());
                    }
                    if (address['state']?.toString().isNotEmpty == true) {
                      addressParts.add(address['state'].toString());
                    }
                    if (address['postalCode']?.toString().isNotEmpty == true) {
                      addressParts.add(address['postalCode'].toString());
                    }

                    formattedAddress = addressParts.join(', ');
                  }

                  return Card(
                    elevation: 4,
                    shadowColor: Colors.black26,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    clipBehavior: Clip.antiAlias,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDisabled ? Colors.red : Colors.blue)
                              .withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 28,
                          color: isDisabled ? Colors.red : Colors.blue,
                        ),
                      ),
                      title: Text(
                        userData['name'] ?? 'No name',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: isDisabled
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['email'] ?? 'No email',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if (formattedAddress.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    formattedAddress,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (isDisabled ? Colors.red : Colors.green)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isDisabled ? 'Disabled' : 'Active',
                              style: TextStyle(
                                color: isDisabled ? Colors.red : Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () =>
                                _showUserDetails(context, userId, userData),
                          ),
                        ],
                      ),
                      onTap: () => _showUserDetails(context, userId, userData),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context, String userId, Map userData) {
    final DateTime? lastLogin = userData['lastLogin'] != null
        ? DateTime.fromMillisecondsSinceEpoch(userData['lastLogin'])
        : null;
    final DateTime? createdAt = userData['createdAt'] != null
        ? DateTime.fromMillisecondsSinceEpoch(userData['createdAt'])
        : null;

    // Format address if it exists
    String? formattedAddress;
    if (userData['address'] != null) {
      final address = userData['address'] as Map;
      final List<String> addressParts = [];

      if (address['line1']?.toString().isNotEmpty == true) {
        addressParts.add(address['line1'].toString());
      }
      if (address['line2']?.toString().isNotEmpty == true) {
        addressParts.add(address['line2'].toString());
      }
      if (address['city']?.toString().isNotEmpty == true) {
        addressParts.add(address['city'].toString());
      }
      if (address['state']?.toString().isNotEmpty == true) {
        addressParts.add(address['state'].toString());
      }
      if (address['postalCode']?.toString().isNotEmpty == true) {
        addressParts.add(address['postalCode'].toString());
      }

      formattedAddress = addressParts.join(', ');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (userData['name'] as String?)?.isNotEmpty == true
                            ? (userData['name'] as String)
                                .characters
                                .first
                                .toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userData['name'] ?? 'No name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userData['email'] ?? 'No email',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: userData['disabled'] == true
                          ? Colors.red[50]
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      userData['disabled'] == true ? 'Disabled' : 'Active',
                      style: TextStyle(
                        color: userData['disabled'] == true
                            ? Colors.red[900]
                            : Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  if (lastLogin != null)
                    _detailRow(
                      'Last Login',
                      '${lastLogin.day}/${lastLogin.month}/${lastLogin.year} at ${lastLogin.hour}:${lastLogin.minute}',
                    ),
                  if (createdAt != null)
                    _detailRow(
                      'Account Created',
                      '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute}',
                    ),
                  if (formattedAddress != null)
                    _detailRow(
                      'Address',
                      formattedAddress,
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Close'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _toggleUserStatus(context, userId, userData),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: userData['disabled'] == true
                                ? const Color.fromARGB(255, 123, 184, 125)
                                : const Color.fromARGB(255, 219, 130, 123),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            userData['disabled'] == true
                                ? 'Enable User'
                                : 'Disable User',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleUserStatus(
      BuildContext context, String userId, Map userData) async {
    try {
      final bool currentStatus = userData['disabled'] == true;
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(userId)
          .update({'disabled': !currentStatus});

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${currentStatus ? 'enabled' : 'disabled'} successfully'),
            backgroundColor: currentStatus ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
