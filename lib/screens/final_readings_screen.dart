import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../services/path_helper.dart';

class FinalReadingsScreen extends StatefulWidget {
  final String projectId;
  final String logId;
  final String logType;

  const FinalReadingsScreen({
    super.key,
    required this.projectId,
    required this.logId,
    required this.logType,
  });

  @override
  State<FinalReadingsScreen> createState() => _FinalReadingsScreenState();
}

class _FinalReadingsScreenState extends State<FinalReadingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _requiresBenzene = false;
  bool _isProjectComplete = false;
  bool _willPerformRecheck = false;

  // Five Minute Readings
  final List<TimeOfDay?> _times = List.filled(5, null);
  final List<TextEditingController> _lelReadings = List.generate(
    5,
    (_) => TextEditingController(),
  );

  // Benzene Reading
  final _benzeneTargetController = TextEditingController();
  TimeOfDay? _benzeneFinalTime;
  final _benzeneReadingController = TextEditingController();

  // Signatures
  final _gemSignatureController = TextEditingController();
  final _facilityRepNameController = TextEditingController();
  final _facilityRepSignatureController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requiresBenzene = widget.logType.toLowerCase().contains('benzene');
  }

  @override
  void dispose() {
    for (var controller in _lelReadings) {
      controller.dispose();
    }
    _benzeneTargetController.dispose();
    _benzeneReadingController.dispose();
    _gemSignatureController.dispose();
    _facilityRepNameController.dispose();
    _facilityRepSignatureController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'fiveMinuteReadings': List.generate(5, (i) => {
          'time': _times[i]?.format(context),
          'lelReading': double.parse(_lelReadings[i].text),
        }),
        'targetConcentration': '10% LEL',
        'isProjectComplete': _isProjectComplete,
        'willPerformRecheck': _willPerformRecheck,
        'gemSignature': _gemSignatureController.text,
        'facilityRepName': _facilityRepNameController.text,
        'facilityRepSignature': _facilityRepSignatureController.text,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (_requiresBenzene) {
        data['benzeneReading'] = {
          'targetConcentration': _benzeneTargetController.text,
          'finalTime': _benzeneFinalTime?.format(context),
          'reading': double.parse(_benzeneReadingController.text),
        };
      }

      await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .collection('logs')
          .doc(widget.logId)
          .collection('finalReadings')
          .doc('final')
          .set(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Final readings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving final readings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTime(int index) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _times[index] = time);
    }
  }

  Future<void> _selectBenzeneTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _benzeneFinalTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Final Readings',
          style: GoogleFonts.nunito(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(),
              const SizedBox(height: 32),
              _buildFiveMinuteReadings(),
              if (_requiresBenzene) ...[
                const SizedBox(height: 32),
                _buildBenzeneSection(),
              ],
              const SizedBox(height: 32),
              _buildCompletionSection(),
              const SizedBox(height: 48),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Degas Target Concentration',
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '10% LEL',
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Degas Five Minute Readings - %LEL PENTANE',
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiveMinuteReadings() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Five Minute Readings',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          ...List.generate(5, (index) => _buildReadingRow(index)),
        ],
      ),
    );
  }

  Widget _buildReadingRow(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              '${index + 1}.',
              style: GoogleFonts.nunito(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _selectTime(index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF374151)),
                ),
                child: Text(
                  _times[index]?.format(context) ?? 'Select Time',
                  style: GoogleFonts.nunito(
                    color: _times[index] != null ? Colors.white : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 100,
            child: TextFormField(
              controller: _lelReadings[index],
              keyboardType: TextInputType.number,
              style: GoogleFonts.nunito(color: Colors.white),
              decoration: InputDecoration(
                hintText: '%LEL',
                hintStyle: GoogleFonts.nunito(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF374151)),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Required';
                }
                if (double.tryParse(value) == null) {
                  return 'Invalid';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenzeneSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Benzene Reading',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _benzeneTargetController,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: _buildInputDecoration('Benzene Target Concentration'),
            validator: (value) => value?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectBenzeneTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF374151)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _benzeneFinalTime?.format(context) ?? 'Select Final Time',
                      style: GoogleFonts.nunito(
                        color: _benzeneFinalTime != null ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                  const Icon(Icons.access_time, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _benzeneReadingController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: _buildInputDecoration('Benzene Reading (PPM)'),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (double.tryParse(value) == null) return 'Invalid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF152042),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Confirmation',
            style: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _gemSignatureController,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: _buildInputDecoration('GEM Signature'),
            validator: (value) => value?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: Text(
              'Project is Complete: Shutdown and Demob',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
            value: _isProjectComplete,
            onChanged: (value) => setState(() => _isProjectComplete = value),
            activeColor: const Color(0xFF2563EB),
          ),
          SwitchListTile(
            title: Text(
              'GEM will perform 12 hour recheck',
              style: GoogleFonts.nunito(color: Colors.white),
            ),
            value: _willPerformRecheck,
            onChanged: (value) => setState(() => _willPerformRecheck = value),
            activeColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _facilityRepNameController,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: _buildInputDecoration('Facility Rep (print name)'),
            validator: (value) => value?.isEmpty == true ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _facilityRepSignatureController,
            style: GoogleFonts.nunito(color: Colors.white),
            decoration: _buildInputDecoration('Facility Rep Signature'),
            validator: (value) => value?.isEmpty == true ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Submit Final Readings'),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.nunito(color: Colors.grey),
      filled: true,
      fillColor: const Color(0xFF1F2937),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
    );
  }
}