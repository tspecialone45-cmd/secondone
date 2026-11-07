import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/extensions/date_extensions.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/attendance_model.dart';
import '../../../data/models/meeting_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/meeting_provider.dart';

class MeetingScreen extends ConsumerStatefulWidget {
  const MeetingScreen({super.key});

  @override
  ConsumerState<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends ConsumerState<MeetingScreen> {
  void _showCreateMeetingDialog() {
    final agendaController = TextEditingController();
    final placeController = TextEditingController(text: 'अध्यक्षांचे घर');
    final timeController = TextEditingController(text: 'सायंकाळी ५:००');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('नवीन मासिक बैठक आयोजित करा'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setModalState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('तारीख: ${selectedDate.toFormattedDate()}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'वेळ',
                  hint: 'उदा. सायंकाळी ५:००',
                  controller: timeController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'ठिकाण',
                  hint: 'उदा. अध्यक्षांचे घर / समाज मंदिर',
                  controller: placeController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'अजेंडा / विषय',
                  hint: 'उदा. मासिक बचत जमा करणे व नवीन कर्ज वाटप चर्चा',
                  controller: agendaController,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('रद्द करा')),
            ElevatedButton(
              onPressed: () async {
                final group = ref.read(currentGroupProvider).value;
                final user = ref.read(currentUserProfileProvider).value;
                if (group == null || user == null) return;

                const uuid = Uuid();
                final meeting = MeetingModel(
                  id: uuid.v4(),
                  groupId: group.id,
                  date: selectedDate,
                  time: timeController.text.trim(),
                  place: placeController.text.trim(),
                  agenda: agendaController.text.trim(),
                  createdBy: user.uid,
                );

                await ref.read(meetingNotifierProvider.notifier).createMeeting(meeting);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('आयोजित करा'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttendanceAndMinutesSheet(MeetingModel meeting) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _MeetingDetailModal(meeting: meeting),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meetings = ref.watch(groupMeetingsProvider).value ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('मासिक बैठका (Meetings)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('नवीन बैठक', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _showCreateMeetingDialog,
      ),
      body: meetings.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text('अद्याप कोणतीही बैठक आयोजित केलेली नाही.'),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: meetings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = meetings[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(m.date.toFormattedDate(),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(m.time, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.secondary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('ठिकाण: ${m.place}', style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('विषय: ${m.agenda}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      if (m.minutes != null && m.minutes!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('इतिवृत्त: ${m.minutes}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                        ),
                      ],
                      const Divider(height: 20),
                      CustomButton(
                        label: 'हजेरी व इतिवृत्त भरा',
                        icon: Icons.checklist,
                        height: 44,
                        isOutlined: true,
                        onPressed: () => _showAttendanceAndMinutesSheet(m),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _MeetingDetailModal extends ConsumerStatefulWidget {
  final MeetingModel meeting;

  const _MeetingDetailModal({required this.meeting});

  @override
  ConsumerState<_MeetingDetailModal> createState() => _MeetingDetailModalState();
}

class _MeetingDetailModalState extends ConsumerState<_MeetingDetailModal> {
  final Map<String, bool> _attendanceMap = {};
  late TextEditingController _minutesController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _minutesController = TextEditingController(text: widget.meeting.minutes ?? '');
    _loadExistingAttendance();
  }

  Future<void> _loadExistingAttendance() async {
    final existing = await ref.read(meetingRepositoryProvider).getAttendanceForMeeting(widget.meeting.id);
    if (mounted) {
      setState(() {
        for (final att in existing) {
          _attendanceMap[att.userId] = att.isPresent;
        }
      });
    }
  }

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  Future<void> _saveAll() async {
    final group = ref.read(currentGroupProvider).value;
    final user = ref.read(currentUserProfileProvider).value;
    final members = ref.read(approvedMembersProvider).value ?? [];

    if (group == null || user == null) return;

    setState(() => _isSaving = true);

    final List<AttendanceModel> attList = [];
    for (final member in members) {
      final isPresent = _attendanceMap[member.uid] ?? true;
      attList.add(AttendanceModel(
        id: '${widget.meeting.id}_${member.uid}',
        meetingId: widget.meeting.id,
        groupId: group.id,
        userId: member.uid,
        memberName: member.name,
        isPresent: isPresent,
        markedBy: user.uid,
      ));
    }

    await ref.read(meetingNotifierProvider.notifier).markAttendance(
          meetingId: widget.meeting.id,
          groupId: group.id,
          attendanceList: attList,
          performedBy: user.uid,
          performedByName: user.name,
        );

    if (_minutesController.text.trim().isNotEmpty) {
      await ref.read(meetingNotifierProvider.notifier).updateMinutes(
            meetingId: widget.meeting.id,
            minutes: _minutesController.text.trim(),
            performedBy: user.uid,
            performedByName: user.name,
            groupId: group.id,
          );
    }

    setState(() => _isSaving = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('हजेरी व इतिवृत्त यशस्वीरित्या जतन केले!'), backgroundColor: AppColors.success),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(approvedMembersProvider).value ?? [];

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text('बैठक: ${widget.meeting.date.toFormattedDate()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('विषय: ${widget.meeting.agenda}', style: const TextStyle(color: AppColors.textSecondary)),
            const Divider(height: 24),

            const Text('सदस्य हजेरी (Attendance)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 10),

            ...members.map((m) {
              final isPresent = _attendanceMap[m.uid] ?? true;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isPresent ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isPresent ? Colors.green.shade200 : Colors.red.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('हजर'),
                          selected: isPresent,
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(color: isPresent ? Colors.white : Colors.black),
                          onSelected: (_) => setState(() => _attendanceMap[m.uid] = true),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('गैरहजर'),
                          selected: !isPresent,
                          selectedColor: Colors.red,
                          labelStyle: TextStyle(color: !isPresent ? Colors.white : Colors.black),
                          onSelected: (_) => setState(() => _attendanceMap[m.uid] = false),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            const Text('बैठकीचे इतिवृत्त / टिप्पण्या (Minutes)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _minutesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'बैठकीत झालेल्या निर्णयांची थोडक्यात नोंद लिहा...',
              ),
            ),
            const SizedBox(height: 24),

            CustomButton(
              label: 'सर्व जतन करा (Save)',
              icon: Icons.check,
              isLoading: _isSaving,
              onPressed: _saveAll,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
