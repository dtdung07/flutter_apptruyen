import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_icon.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RatingSelector extends StatefulWidget {
  final String idBook;
  final double currentRate;
  final int countRate;

  const RatingSelector({
    super.key,
    required this.idBook,
    required this.currentRate,
    required this.countRate,
  });

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  int? selectedIndex;
  String? uid;
  bool isRate = false;

  Future<void> checkUserRate(String uid) async {
    print('Kiểm tra đánh giá người dùng');
    final documentSnapshot = await FirebaseFirestore.instance
        .collection('books')
        .doc(widget.idBook)
        .collection('rate')
        .where('user_id', isEqualTo: uid)
        .get();
    if (documentSnapshot.docs.isNotEmpty) {
      isRate = true;
      final data = documentSnapshot.docs.first.data() as Map;
      setState(() {
        selectedIndex = data['user_rate'];
      });
    } else {
      print('Người dùng chưa đánh giá truyện này');
    }
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      checkUserRate(uid!);
    }
  }

  final List<Map<String, dynamic>> items = [
    {
      'icon': 'lib/images/rate_icons/rate-5.webp',
      'text': 'Tuyệt vời',
      'color': Colors.green,
      'point': 10,
    },
    {
      'icon': 'lib/images/rate_icons/rate-4.webp',
      'text': 'Hay nha',
      'color': Colors.green,
      'point': 8,
    },
    {
      'icon': 'lib/images/rate_icons/rate-3.webp',
      'text': 'Khá ổn',
      'color': Colors.green,
      'point': 6,
    },
    {
      'icon': 'lib/images/rate_icons/rate-2.webp',
      'text': 'Chán ngắt',
      'color': Colors.green,
      'point': 4,
    },
    {
      'icon': 'lib/images/rate_icons/rate-1.webp',
      'text': 'Dở tệ',
      'color': Colors.green,
      'point': 2,
    },
  ];

  Future<void> _rate({
    required String userID,
    required String bookID,
    required double oldTotal,
    required int newRating,
    required int indexRate,
    required int oldCount,
  }) async {
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookID)
        .collection('rate')
        .add(
      {
        'user_id': userID,
        'user_rate': indexRate,
      },
    );
    final newCount = oldCount + 1;
    final newPoint = (oldTotal + newRating) / newCount;
    await FirebaseFirestore.instance
        .collection('books')
        .doc(bookID)
        .set({'rate': newPoint, 'count': newCount});

    print('Đã lưu đánh giá: $newRating điểm, điểm trung bình mới: $newPoint');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                return RateWidget(
                  isSelected: ((selectedIndex == index) ||
                      (isRate && selectedIndex == index)),
                  onTap: () {
                    if (!isRate) {
                      setState(() {
                        selectedIndex = index;
                      });
                    }
                  },
                  imageIcon: item['icon'],
                  textIcon: item['text'],
                  activeColor: item['color'],
                );
              },
            ),
          ),
        ),
        const SizedBox(
          height: 30,
        ),
        Row(
          children: [
            Button_Info(
              text: 'Gửi đánh giá',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              flex: 1,
              ontap: () {
                if (selectedIndex != null && uid != null && isRate == false) {
                  final itemIcon = items[selectedIndex!];
                  _rate(
                    userID: uid!,
                    bookID: widget.idBook,
                    newRating: itemIcon['point'],
                    indexRate: selectedIndex!,
                    oldTotal: widget.currentRate,
                    oldCount: widget.countRate,
                  );
                  Navigator.pop(context);
                } else if (uid == null) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('Vui lòng đăng nhập'),
                      );
                    },
                  );
                } else if (isRate) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        content: Text('Bạn đã đánh giá truyện này rồi'),
                      );
                    },
                  );
                }
              },
            ),
            const SizedBox(
              width: 10,
            ),
            Button_Info(
              text: 'Huỷ',
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              flex: 1,
              ontap: () {
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      ],
    );
  }
}
