// lib/screens/tabs/days_tab.dart
// 行程天數頁籤：顯示每天的景點與交通

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import '../../models/trip_model.dart';
import '../../services/storage_service.dart';

class DaysTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function(Trip) onSave;
  final bool canEdit;
  const DaysTab({super.key, required this.trip, required this.onSave, required this.canEdit});

  @override
  State<DaysTab> createState() => _DaysTabState();
}

class _DaysTabState extends State<DaysTab> {
  final _uuid = const Uuid();
  late Trip _trip;

  @override
  void initState() {
    super.initState();
    _trip = widget.trip;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: _trip.days.isEmpty
          ? _emptyDays()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _trip.days.length,
              itemBuilder: (_, i) => _DayCard(
                day: _trip.days[i],
                inviteCode: _trip.inviteCode,
                canEdit: widget.canEdit,
                onDayUpdated: (updated) => _updateDay(updated),
              ),
            ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _addDay,
              backgroundColor: const Color(0xFF5B8A72),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('新增天數'),
            )
          : null,
    );
  }

  Widget _emptyDays() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 60, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('還沒有行程', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
            if (widget.canEdit) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _addDay,
                icon: const Icon(Icons.add),
                label: const Text('新增第一天'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A72),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );

  void _addDay() async {
    final dayNum = _trip.days.length + 1;
    final newDay = TripDay(
      id: _uuid.v4(),
      dayNumber: dayNum,
      date: '',
      title: '第 $dayNum 天',
      places: [],
      transports: [],
      lastModified: DateTime.now(),
    );
    final updatedTrip = _trip.copyWith(
      days: [..._trip.days, newDay],
      lastModified: DateTime.now(),
    );
    await widget.onSave(updatedTrip);
    setState(() => _trip = updatedTrip);
  }

  void _updateDay(TripDay updated) async {
    final days = _trip.days.map((d) => d.id == updated.id ? updated : d).toList();
    final updatedTrip = _trip.copyWith(days: days, lastModified: DateTime.now());
    await widget.onSave(updatedTrip);
    setState(() => _trip = updatedTrip);
  }
}

// ── 單天卡片 ─────────────────────────────────
class _DayCard extends StatelessWidget {
  final TripDay day;
  final String inviteCode;
  final bool canEdit;
  final Function(TripDay) onDayUpdated;
  const _DayCard({
    required this.day,
    required this.inviteCode,
    required this.canEdit,
    required this.onDayUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 天數標題
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B8A72),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '第 ${day.dayNumber} 天',
                    style: const TextStyle(color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    day.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canEdit)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _editDayTitle(context),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 景點列表
          if (day.places.isEmpty && day.transports.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text('還沒有內容', style: TextStyle(color: Colors.grey.shade400)),
            ),

          ...day.places.map((place) => _PlaceTile(
            place: place,
            inviteCode: inviteCode,
            canEdit: canEdit,
            onEdit: (updated) {
              final places = day.places.map((p) => p.id == updated.id ? updated : p).toList();
              onDayUpdated(day.copyWith(places: places, lastModified: DateTime.now()));
            },
            onDelete: () {
              final places = day.places.where((p) => p.id != place.id).toList();
              onDayUpdated(day.copyWith(places: places, lastModified: DateTime.now()));
            },
          )),

          // 交通列表
          if (day.transports.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('交通', style: TextStyle(
                fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ),
          ...day.transports.map((t) => _TransportTile(
            transport: t,
            canEdit: canEdit,
            onEdit: (updated) {
              final ts = day.transports.map((tr) => tr.id == updated.id ? updated : tr).toList();
              onDayUpdated(day.copyWith(transports: ts, lastModified: DateTime.now()));
            },
            onDelete: () {
              final ts = day.transports.where((tr) => tr.id != t.id).toList();
              onDayUpdated(day.copyWith(transports: ts, lastModified: DateTime.now()));
            },
          )),

          // 新增按鈕
          if (canEdit)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  _AddButton(
                    icon: Icons.place_outlined,
                    label: '新增景點',
                    onTap: () => _addPlace(context),
                  ),
                  const SizedBox(width: 8),
                  _AddButton(
                    icon: Icons.directions_bus_outlined,
                    label: '新增交通',
                    onTap: () => _addTransport(context),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _editDayTitle(BuildContext context) async {
    final controller = TextEditingController(text: day.title);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('編輯標題'),
        content: TextField(controller: controller, decoration:
            const InputDecoration(labelText: '天數標題')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('確定')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      onDayUpdated(day.copyWith(title: result, lastModified: DateTime.now()));
    }
  }

  void _addPlace(BuildContext context) async {
    final result = await _showPlaceEditDialog(context, null);
    if (result != null) {
      onDayUpdated(day.copyWith(
        places: [...day.places, result],
        lastModified: DateTime.now(),
      ));
    }
  }

  void _addTransport(BuildContext context) async {
    final result = await _showTransportEditDialog(context, null);
    if (result != null) {
      onDayUpdated(day.copyWith(
        transports: [...day.transports, result],
        lastModified: DateTime.now(),
      ));
    }
  }

  Future<PlaceItem?> _showPlaceEditDialog(BuildContext context, PlaceItem? existing) async {
    final uuid = const Uuid();
    final timeCtrl = TextEditingController(text: existing?.time ?? '');
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    String imagePath = existing?.imagePath ?? '';
    File? pickedImage;

    return showModalBottomSheet<PlaceItem>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20,
              20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? '新增景點' : '編輯景點',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextField(controller: timeCtrl,
                    decoration: const InputDecoration(labelText: '時間', hintText: '10:00'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: TextField(controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '景點名稱'))),
              ]),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2,
                  decoration: const InputDecoration(labelText: '描述（選填）')),
              const SizedBox(height: 12),
              // 圖片選擇
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final img = await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) {
                    setModalState(() => pickedImage = File(img.path));
                  }
                },
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: pickedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(pickedImage!, fit: BoxFit.cover, width: double.infinity))
                      : const Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                            Text('點擊上傳圖片', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ])),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty) return;
                    String savedPath = imagePath;
                    if (pickedImage != null) {
                      final imgId = uuid.v4();
                      savedPath = await StorageService.instance.savePlaceImage(
                        inviteCode: inviteCode,
                        dayId: day.id,
                        imageId: imgId,
                        sourceFile: pickedImage!,
                      );
                    }
                    Navigator.pop(ctx, PlaceItem(
                      id: existing?.id ?? uuid.v4(),
                      time: timeCtrl.text,
                      name: nameCtrl.text,
                      description: descCtrl.text,
                      imagePath: savedPath,
                      lastModified: DateTime.now(),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B8A72),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('儲存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<TransportInfo?> _showTransportEditDialog(BuildContext context, TransportInfo? existing) async {
    final uuid = const Uuid();
    final timeCtrl = TextEditingController(text: existing?.departureTime ?? '');
    final fromCtrl = TextEditingController(text: existing?.departurePlace ?? '');
    final toCtrl = TextEditingController(text: existing?.arrivalPlace ?? '');
    final typeCtrl = TextEditingController(text: existing?.transportType ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    return showModalBottomSheet<TransportInfo>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20,
            20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(existing == null ? '新增交通' : '編輯交通',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextField(controller: timeCtrl,
                  decoration: const InputDecoration(labelText: '出發時間'))),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: TextField(controller: typeCtrl,
                  decoration: const InputDecoration(labelText: '交通方式', hintText: '捷運、公車…'))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: TextField(controller: fromCtrl,
                  decoration: const InputDecoration(labelText: '從哪裡'))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward, color: Colors.grey)),
              Expanded(child: TextField(controller: toCtrl,
                  decoration: const InputDecoration(labelText: '到哪裡'))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: noteCtrl,
                decoration: const InputDecoration(labelText: '備註（選填）')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (fromCtrl.text.isEmpty || toCtrl.text.isEmpty) return;
                  Navigator.pop(ctx, TransportInfo(
                    id: existing?.id ?? uuid.v4(),
                    departureTime: timeCtrl.text,
                    departurePlace: fromCtrl.text,
                    arrivalPlace: toCtrl.text,
                    transportType: typeCtrl.text,
                    note: noteCtrl.text,
                    lastModified: DateTime.now(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B8A72),
                  foregroundColor: Colors.white,
                ),
                child: const Text('儲存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 景點 tile ─────────────────────────────────
class _PlaceTile extends StatelessWidget {
  final PlaceItem place;
  final String inviteCode;
  final bool canEdit;
  final Function(PlaceItem) onEdit;
  final VoidCallback onDelete;
  const _PlaceTile({
    required this.place, required this.inviteCode,
    required this.canEdit, required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            const SizedBox(height: 4),
            Container(width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFF5B8A72), shape: BoxShape.circle)),
            Container(width: 1, height: 40, color: Colors.grey.shade300),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.imagePath.isNotEmpty)
                    FutureBuilder<File>(
                      future: StorageService.instance.resolveImageFile(inviteCode, place.imagePath),
                      builder: (_, snap) {
                        if (snap.hasData) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(snap.data!, width: 56, height: 56, fit: BoxFit.cover),
                          );
                        }
                        return const SizedBox(width: 56, height: 56);
                      },
                    ),
                  if (place.imagePath.isNotEmpty) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          if (place.time.isNotEmpty)
                            Text(place.time,
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          if (place.time.isNotEmpty) const SizedBox(width: 6),
                          Expanded(child: Text(place.name,
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                        ]),
                        if (place.description.isNotEmpty)
                          Text(place.description,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (canEdit)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showOptions(context),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_outlined),
                title: const Text('編輯'), onTap: () { Navigator.pop(context); /* TODO */ }),
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('刪除', style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); onDelete(); }),
          ],
        ),
      ),
    );
  }
}

// ── 交通 tile ─────────────────────────────────
class _TransportTile extends StatelessWidget {
  final TransportInfo transport;
  final bool canEdit;
  final Function(TransportInfo) onEdit;
  final VoidCallback onDelete;
  const _TransportTile({
    required this.transport, required this.canEdit,
    required this.onEdit, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_outlined, size: 16, color: Color(0xFF5B8A72)),
          const SizedBox(width: 8),
          if (transport.departureTime.isNotEmpty) ...[
            Text(transport.departureTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              '${transport.departurePlace} → ${transport.arrivalPlace}',
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(transport.transportType,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.grey),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

// ── 新增按鈕 ─────────────────────────────────
class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF5B8A72).withOpacity(0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF5B8A72)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF5B8A72))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── copyWith 擴充 ─────────────────────────────
extension TripDayCopy on TripDay {
  TripDay copyWith({
    String? title, List<PlaceItem>? places,
    List<TransportInfo>? transports, DateTime? lastModified,
  }) {
    return TripDay(
      id: id, dayNumber: dayNumber, date: date,
      title: title ?? this.title,
      places: places ?? this.places,
      transports: transports ?? this.transports,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}

extension TripCopy on Trip {
  Trip copyWith({
    String? title, List<TripDay>? days, List<FlightInfo>? flights,
    List<HotelInfo>? hotels, List<SouvenirItem>? souvenirs,
    DateTime? lastModified, String? coverImagePath,
  }) {
    return Trip(
      id: id, inviteCode: inviteCode,
      title: title ?? this.title,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      days: days ?? this.days,
      flights: flights ?? this.flights,
      hotels: hotels ?? this.hotels,
      souvenirs: souvenirs ?? this.souvenirs,
      members: members,
      createdAt: createdAt,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}