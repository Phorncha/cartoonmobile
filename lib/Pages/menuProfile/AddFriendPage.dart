import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> searchResults = [];

// ค้นหาผู้ใช้ตามชื่อผู้ใช้ที่ระบุใน searchText
  void searchFriend(String searchText) async {
    try {
      // ตรวจสอบว่า searchText ไม่ว่างเปล่า
      if (searchText.isNotEmpty) {
        final QuerySnapshot<Map<String, dynamic>> result = await _firestore
            .collection('users')
            .where('username', isEqualTo: searchText)
            .get();

        setState(() {
          searchResults =
              result.docs.map((doc) => doc['username'] as String).toList();
        });
      } else {
        // ถ้า searchText ว่างเปล่า ให้แสดงข้อความ "ไม่พบข้อมูลผู้ใช้ที่ค้นหา"
        setState(() {
          searchResults = [];
        });
      }
    } catch (e) {
      print('Error searching for friend: $e');
    }
  }

  // ฟังก์ชันเพิ่มเพื่อน
  void addFriend(String friendUsername) async {
    try {
      // ดึงข้อมูลของผู้ใช้ปัจจุบัน
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        String currentUserId = currentUser.uid;

        DocumentReference<Map<String, dynamic>> currentUserRef =
            _firestore.collection('users').doc(currentUserId);

        DocumentSnapshot<Map<String, dynamic>> currentUserDoc =
            await currentUserRef.get();

        if (currentUserDoc.exists) {
          // ดึงรายชื่อเพื่อนที่มีอยู่แล้ว
          List<String> currentFriends =
              currentUserDoc.data()?['friends']?.cast<String>() ?? [];

          // ตรวจสอบว่าเพื่อนที่จะเพิ่มยังไม่ได้เพิ่มมาก่อน
          if (!currentFriends.contains(friendUsername)) {
            // เพิ่มเพื่อนใหม่
            currentFriends.add(friendUsername);

            // อัปเดตข้อมูลใน Firestore
            await currentUserRef.update({'friends': currentFriends});

            // Optional: ตัวอย่างการแสดงข้อความใน console
            print('Friend added successfully: $friendUsername');

            // แสดง SnackBar ว่าเพื่อนถูกเพิ่ม
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เพื่อน $friendUsername ถูกเพิ่มแล้ว'),
              ),
            );
          } else {
            // ถ้าผู้ใช้มีเพื่อนคนนี้อยู่แล้ว
            print('User $friendUsername is already a friend.');

            // แสดง SnackBar ว่ามีผู้ใช้เป็นเพื่อนแล้ว
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ผู้ใช้ $friendUsername เป็นเพื่อนอยู่แล้ว'),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error adding friend: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'ป้อนชื่อเพื่อน',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        searchFriend(_searchController.text);
                      },
                      icon: Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: Container(
                height: 70, // ปรับค่าตามที่ต้องการ
                color: Colors.white,
                child: _searchController.text.isEmpty
                    ? Center(
                        child: Text(
                          '',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : searchResults.isEmpty
                        ? Center(
                            child: Text(
                              'ไม่พบข้อมูลผู้ใช้ที่ค้นหา',
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              return Card(
                                child: ListTile(
                                  title: Text(searchResults[index]),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.person_add),
                                        onPressed: () {
                                          print(
                                              'Adding friend: ${searchResults[index]}');
                                          addFriend(searchResults[index]);
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          // ตัวอย่าง: ลบ(searchResults[index]);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
            SizedBox(height: 20),
            Flexible(
              child: Container(
                color: Colors.white,
                child: _searchController.text.isEmpty
                    ? Center(
                        child: Text(
                          '',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          return Card();
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
