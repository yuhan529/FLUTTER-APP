
// lib/screens/tabs/flights_tab.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/trip_model.dart';
import '../tabs/days_tab.dart' show TripCopy;

class FlightsTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function(Trip) onSave;
  final bool canEdit;
  const FlightsTab({super.key, required this.trip, required this.onSave, required this.canEdit});

  @override
  State<FlightsTab> createState() => _FlightsTabState();
}

class _FlightsTabState extends State<FlightsTab> {
  late Trip _trip;
  final _uuid = const Uuid();

  @override
  void initState() { super.initState(); _trip = widget.trip; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: _trip.flights.isEmpty
          ? _empty()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _trip.flights.length,
              itemBuilder: (_, i) => _FlightCard(
                flight: _trip.flights[i],
                canEdit: widget.canEdit,
                onDelete: () => _deleteFlight(_trip.flights[i].id),
              ),
            ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _addFlight,
              backgroundColor: const Color(0xFF5B8A72),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('新增機票'),
            )
          : null,
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.flight_outlined, size: 60, color: Colors.grey.shade400),
      const SizedBox(height: 12),
      Text('還沒有機票資訊', style: TextStyle(color: Colors.grey.shade500)),
    ]),
  );

  void _addFlight() async {
    final result = await _showFlightDialog(context, null);
    if (result != null) {
      final updated = _trip.copyWith(
        flights: [..._trip.flights, result],
        lastModified: DateTime.now(),
      );
      await widget.onSave(updated);
      setState(() => _trip = updated);
    }
  }

  void _deleteFlight(String id) async {
    final updated = _trip.copyWith(
      flights: _trip.flights.where((f) => f.id != id).toList(),
      lastModified: DateTime.now(),
    );
    await widget.onSave(updated);
    setState(() => _trip = updated);
  }

  Future<FlightInfo?> _showFlightDialog(BuildContext context, FlightInfo? existing) {
    final flightCtrl = TextEditingController(text: existing?.flightNumber ?? '');
    final airlineCtrl = TextEditingController(text: existing?.airline ?? '');
    final fromCtrl = TextEditingController(text: existing?.departureAirport ?? '');
    final toCtrl = TextEditingController(text: existing?.arrivalAirport ?? '');
    final depCtrl = TextEditingController(text: existing?.departureTime ?? '');
    final arrCtrl = TextEditingController(text: existing?.arrivalTime ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    return showModalBottomSheet<FlightInfo>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('機票資訊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: flightCtrl,
                decoration: const InputDecoration(labelText: '航班號碼', hintText: 'JL801'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: airlineCtrl,
                decoration: const InputDecoration(labelText: '航空公司'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: fromCtrl,
                decoration: const InputDecoration(labelText: '出發機場', hintText: 'TPE'))),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, color: Colors.grey)),
            Expanded(child: TextField(controller: toCtrl,
                decoration: const InputDecoration(labelText: '抵達機場', hintText: 'NRT'))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: depCtrl,
                decoration: const InputDecoration(labelText: '起飛時間', hintText: '2025-03-15 08:30'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: arrCtrl,
                decoration: const InputDecoration(labelText: '降落時間'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, maxLines: 2,
              decoration: const InputDecoration(labelText: '備註（座位、行李額…）')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx, FlightInfo(
                id: existing?.id ?? _uuid.v4(),
                flightNumber: flightCtrl.text,
                airline: airlineCtrl.text,
                departureAirport: fromCtrl.text,
                arrivalAirport: toCtrl.text,
                departureTime: depCtrl.text,
                arrivalTime: arrCtrl.text,
                note: noteCtrl.text,
                lastModified: DateTime.now(),
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8A72), foregroundColor: Colors.white),
            child: const Text('儲存'),
          )),
        ]),
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  final FlightInfo flight;
  final bool canEdit;
  final VoidCallback onDelete;
  const _FlightCard({required this.flight, required this.canEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.flight, color: Color(0xFF5B8A72), size: 20),
          const SizedBox(width: 8),
          Text(flight.flightNumber,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
          const SizedBox(width: 8),
          Text(flight.airline, style: TextStyle(color: Colors.grey.shade600)),
          const Spacer(),
          if (canEdit) IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
            onPressed: onDelete,
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(flight.departureAirport,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(flight.departureTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
          const Icon(Icons.arrow_forward, color: Colors.grey),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(flight.arrivalAirport,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(flight.arrivalTime,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ])),
        ]),
        if (flight.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(flight.note, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// lib/screens/tabs/hotels_tab.dart
// ═══════════════════════════════════════════════════════

class HotelsTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function(Trip) onSave;
  final bool canEdit;
  const HotelsTab({super.key, required this.trip, required this.onSave, required this.canEdit});

  @override
  State<HotelsTab> createState() => _HotelsTabState();
}

class _HotelsTabState extends State<HotelsTab> {
  late Trip _trip;
  final _uuid = const Uuid();

  @override
  void initState() { super.initState(); _trip = widget.trip; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: _trip.hotels.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.hotel_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('還沒有住宿資訊', style: TextStyle(color: Colors.grey.shade500)),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: _trip.hotels.length,
              itemBuilder: (_, i) => _HotelCard(
                hotel: _trip.hotels[i],
                canEdit: widget.canEdit,
                onDelete: () => _delete(_trip.hotels[i].id),
              ),
            ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: const Color(0xFF5B8A72),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add), label: const Text('新增住宿'))
          : null,
    );
  }

  void _add() async {
    final result = await _showDialog(context, null);
    if (result != null) {
      final updated = _trip.copyWith(
        hotels: [..._trip.hotels, result], lastModified: DateTime.now());
      await widget.onSave(updated);
      setState(() => _trip = updated);
    }
  }

  void _delete(String id) async {
    final updated = _trip.copyWith(
      hotels: _trip.hotels.where((h) => h.id != id).toList(),
      lastModified: DateTime.now());
    await widget.onSave(updated);
    setState(() => _trip = updated);
  }

  Future<HotelInfo?> _showDialog(BuildContext context, HotelInfo? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final inCtrl = TextEditingController(text: existing?.checkIn ?? '');
    final outCtrl = TextEditingController(text: existing?.checkOut ?? '');
    final codeCtrl = TextEditingController(text: existing?.confirmationCode ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    return showModalBottomSheet<HotelInfo>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('住宿資訊', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '飯店名稱')),
          const SizedBox(height: 12),
          TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: '地址')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextField(controller: inCtrl,
                decoration: const InputDecoration(labelText: 'Check-in', hintText: '2025-03-15'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: outCtrl,
                decoration: const InputDecoration(labelText: 'Check-out'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: codeCtrl,
              decoration: const InputDecoration(labelText: '訂房確認碼')),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, maxLines: 3,
              decoration: const InputDecoration(
                  labelText: '備註', hintText: '停車場、早餐時間、注意事項…')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, HotelInfo(
              id: existing?.id ?? _uuid.v4(),
              name: nameCtrl.text, address: addrCtrl.text,
              checkIn: inCtrl.text, checkOut: outCtrl.text,
              confirmationCode: codeCtrl.text, note: noteCtrl.text,
              lastModified: DateTime.now(),
            )),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8A72), foregroundColor: Colors.white),
            child: const Text('儲存'),
          )),
        ]),
      ),
    );
  }
}

class _HotelCard extends StatelessWidget {
  final HotelInfo hotel;
  final bool canEdit;
  final VoidCallback onDelete;
  const _HotelCard({required this.hotel, required this.canEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.hotel, color: Color(0xFF5B8A72), size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(hotel.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
          if (canEdit) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
              onPressed: onDelete),
        ]),
        const SizedBox(height: 6),
        Text(hotel.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        const SizedBox(height: 8),
        Row(children: [
          _InfoChip(icon: Icons.login, text: hotel.checkIn),
          const SizedBox(width: 8),
          _InfoChip(icon: Icons.logout, text: hotel.checkOut),
        ]),
        if (hotel.confirmationCode.isNotEmpty) ...[
          const SizedBox(height: 6),
          _InfoChip(icon: Icons.confirmation_number_outlined, text: hotel.confirmationCode),
        ],
        if (hotel.note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(child: Text(hotel.note, style: const TextStyle(fontSize: 12))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// lib/screens/tabs/souvenirs_tab.dart
// ═══════════════════════════════════════════════════════

class SouvenirsTab extends StatefulWidget {
  final Trip trip;
  final Future<void> Function(Trip) onSave;
  final bool canEdit;
  const SouvenirsTab({super.key, required this.trip, required this.onSave, required this.canEdit});

  @override
  State<SouvenirsTab> createState() => _SouvenirsTabState();
}

class _SouvenirsTabState extends State<SouvenirsTab> {
  late Trip _trip;
  final _uuid = const Uuid();

  @override
  void initState() { super.initState(); _trip = widget.trip; }

  @override
  Widget build(BuildContext context) {
    final unpurchased = _trip.souvenirs.where((s) => !s.isPurchased).toList();
    final purchased = _trip.souvenirs.where((s) => s.isPurchased).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      body: _trip.souvenirs.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text('還沒有伴手禮清單', style: TextStyle(color: Colors.grey.shade500)),
            ]))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                if (unpurchased.isNotEmpty) ...[
                  const _SectionHeader(title: '待購買', icon: Icons.radio_button_unchecked),
                  ...unpurchased.map((s) => _SouvenirCard(
                    souvenir: s, inviteCode: _trip.inviteCode, canEdit: widget.canEdit,
                    onToggle: () => _toggle(s), onDelete: () => _delete(s.id),
                  )),
                ],
                if (purchased.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const _SectionHeader(title: '已購買', icon: Icons.check_circle_outline),
                  ...purchased.map((s) => _SouvenirCard(
                    souvenir: s, inviteCode: _trip.inviteCode, canEdit: widget.canEdit,
                    onToggle: () => _toggle(s), onDelete: () => _delete(s.id),
                  )),
                ],
              ],
            ),
      floatingActionButton: widget.canEdit
          ? FloatingActionButton.extended(
              onPressed: _add,
              backgroundColor: const Color(0xFF5B8A72),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add), label: const Text('新增伴手禮'))
          : null,
    );
  }

  void _toggle(SouvenirItem s) async {
    final updated = _trip.copyWith(
      souvenirs: _trip.souvenirs.map((item) => item.id == s.id
          ? SouvenirItem(
              id: s.id, name: s.name, shopName: s.shopName,
              shopLocation: s.shopLocation, price: s.price,
              currency: s.currency, imagePath: s.imagePath,
              isPurchased: !s.isPurchased, note: s.note,
              lastModified: DateTime.now())
          : item).toList(),
      lastModified: DateTime.now(),
    );
    await widget.onSave(updated);
    setState(() => _trip = updated);
  }

  void _delete(String id) async {
    final updated = _trip.copyWith(
      souvenirs: _trip.souvenirs.where((s) => s.id != id).toList(),
      lastModified: DateTime.now());
    await widget.onSave(updated);
    setState(() => _trip = updated);
  }

  void _add() async {
    final result = await _showDialog(context, null);
    if (result != null) {
      final updated = _trip.copyWith(
        souvenirs: [..._trip.souvenirs, result], lastModified: DateTime.now());
      await widget.onSave(updated);
      setState(() => _trip = updated);
    }
  }

  Future<SouvenirItem?> _showDialog(BuildContext context, SouvenirItem? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final shopCtrl = TextEditingController(text: existing?.shopName ?? '');
    final locCtrl = TextEditingController(text: existing?.shopLocation ?? '');
    final priceCtrl = TextEditingController(
        text: existing?.price != null ? existing!.price.toString() : '');
    final currencyCtrl = TextEditingController(text: existing?.currency ?? 'JPY');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    return showModalBottomSheet<SouvenirItem>(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('新增伴手禮', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名稱')),
          const SizedBox(height: 12),
          TextField(controller: shopCtrl, decoration: const InputDecoration(labelText: '店家名稱')),
          const SizedBox(height: 12),
          TextField(controller: locCtrl, decoration: const InputDecoration(labelText: '購買地點')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(flex: 2, child: TextField(controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: '價格'))),
            const SizedBox(width: 12),
            Expanded(child: TextField(controller: currencyCtrl,
                decoration: const InputDecoration(labelText: '幣別'))),
          ]),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: '備註')),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.pop(ctx, SouvenirItem(
              id: existing?.id ?? _uuid.v4(),
              name: nameCtrl.text,
              shopName: shopCtrl.text,
              shopLocation: locCtrl.text,
              price: double.tryParse(priceCtrl.text) ?? 0,
              currency: currencyCtrl.text,
              lastModified: DateTime.now(),
            )),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B8A72), foregroundColor: Colors.white),
            child: const Text('儲存'),
          )),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 6),
        Text(title, style: TextStyle(
            fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SouvenirCard extends StatelessWidget {
  final SouvenirItem souvenir;
  final String inviteCode;
  final bool canEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  const _SouvenirCard({
    required this.souvenir, required this.inviteCode,
    required this.canEdit, required this.onToggle, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: souvenir.isPurchased ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        GestureDetector(
          onTap: canEdit ? onToggle : null,
          child: Icon(
            souvenir.isPurchased ? Icons.check_circle : Icons.radio_button_unchecked,
            color: souvenir.isPurchased ? const Color(0xFF5B8A72) : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(souvenir.name, style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: souvenir.isPurchased ? TextDecoration.lineThrough : null,
              color: souvenir.isPurchased ? Colors.grey : null)),
          Text('${souvenir.shopName}・${souvenir.shopLocation}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          if (souvenir.price > 0)
            Text('${souvenir.currency} ${souvenir.price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF5B8A72))),
        ])),
        if (canEdit) IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 18),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}