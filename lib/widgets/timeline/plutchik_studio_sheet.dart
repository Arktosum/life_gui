import 'package:flutter/material.dart';
import '../../models/mood_preset.dart';
import '../../database/database_helper.dart';

class PlutchikStudioSheet extends StatefulWidget {
  final String? initialName;
  final MoodPreset?
  existingPreset; // NEW: If this is passed, we are in Edit Mode!

  const PlutchikStudioSheet({super.key, this.initialName, this.existingPreset});

  @override
  State<PlutchikStudioSheet> createState() => _PlutchikStudioSheetState();
}

class _PlutchikStudioSheetState extends State<PlutchikStudioSheet> {
  late TextEditingController _nameController;
  late TextEditingController _emojiController;

  double _joy = 0.0, _trust = 0.0, _fear = 0.0, _surprise = 0.0;
  double _sadness = 0.0, _disgust = 0.0, _anger = 0.0, _anticipation = 0.0;

  bool get _isEditing => widget.existingPreset != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existingPreset!;
      _nameController = TextEditingController(text: p.name);
      _emojiController = TextEditingController(text: p.emoji);
      _joy = p.joy;
      _trust = p.trust;
      _fear = p.fear;
      _surprise = p.surprise;
      _sadness = p.sadness;
      _disgust = p.disgust;
      _anger = p.anger;
      _anticipation = p.anticipation;
    } else {
      _nameController = TextEditingController(text: widget.initialName ?? '');
      _emojiController = TextEditingController(text: '🧠');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _savePreset() async {
    final name = _nameController.text.trim();
    final emoji = _emojiController.text.trim();

    if (name.isEmpty || emoji.isEmpty) return;

    final presetMap = {
      if (_isEditing)
        'id': widget.existingPreset!.id, // Keep the ID if updating
      'name': name,
      'emoji': emoji,
      'joy': _joy, 'trust': _trust, 'fear': _fear, 'surprise': _surprise,
      'sadness': _sadness,
      'disgust': _disgust,
      'anger': _anger,
      'anticipation': _anticipation,
    };

    final id = await DatabaseHelper.instance.insertMoodPreset(presetMap);

    if (mounted) {
      // Return the complete object back to the sheet
      Navigator.pop(
        context,
        MoodPreset.fromMap({
          'id': _isEditing ? widget.existingPreset!.id : id,
          ...presetMap,
        }),
      );
    }
  }

  Future<void> _deletePreset() async {
    if (_isEditing && widget.existingPreset!.id != null) {
      await DatabaseHelper.instance.deleteMoodPreset(
        widget.existingPreset!.id!,
      );
      if (mounted)
        Navigator.pop(
          context,
          'DELETED',
        ); // Send a special signal back to remove it from the UI!
    }
  }

  Widget _buildEmotionSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '${(value * 100).toInt()}%',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: color.withOpacity(0.2),
              thumbColor: color,
              overlayColor: color.withOpacity(0.1),
              trackHeight: 6.0,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: Colors.cyanAccent),
                      SizedBox(width: 8),
                      Text(
                        'Plutchik Studio',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.cyanAccent,
                        ),
                      ),
                    ],
                  ),
                  if (_isEditing) // NEW: The Trash Can!
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: _deletePreset,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _isEditing
                    ? 'Tweak the emotional mix for this state.'
                    : 'Mix the primary emotions to define this mental state.',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: TextField(
                      controller: _emojiController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 28),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        labelText: 'State Name',
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildEmotionSlider(
                      'Joy',
                      _joy,
                      Colors.yellowAccent,
                      (v) => setState(() => _joy = v),
                    ),
                    _buildEmotionSlider(
                      'Trust',
                      _trust,
                      Colors.lightGreenAccent,
                      (v) => setState(() => _trust = v),
                    ),
                    _buildEmotionSlider(
                      'Fear',
                      _fear,
                      Colors.greenAccent.shade700,
                      (v) => setState(() => _fear = v),
                    ),
                    _buildEmotionSlider(
                      'Surprise',
                      _surprise,
                      Colors.lightBlueAccent,
                      (v) => setState(() => _surprise = v),
                    ),
                    _buildEmotionSlider(
                      'Sadness',
                      _sadness,
                      Colors.blueAccent,
                      (v) => setState(() => _sadness = v),
                    ),
                    _buildEmotionSlider(
                      'Disgust',
                      _disgust,
                      Colors.purpleAccent,
                      (v) => setState(() => _disgust = v),
                    ),
                    _buildEmotionSlider(
                      'Anger',
                      _anger,
                      Colors.redAccent,
                      (v) => setState(() => _anger = v),
                    ),
                    _buildEmotionSlider(
                      'Anticipation',
                      _anticipation,
                      Colors.orangeAccent,
                      (v) => setState(() => _anticipation = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _savePreset,
                  child: Text(
                    _isEditing ? 'UPDATE PRESET' : 'SAVE TO DICTIONARY',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}
