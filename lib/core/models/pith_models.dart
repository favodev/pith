import 'package:flutter/material.dart';

class ShellTabItem {
  const ShellTabItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class DeckSummary {
  const DeckSummary({
    required this.totalBirthdays,
    required this.title,
    required this.subtitle,
    required this.avatars,
  });

  final int totalBirthdays;
  final String title;
  final String subtitle;
  final List<String> avatars;
}

class PulseItem {
  const PulseItem({
    required this.name,
    required this.meta,
    required this.detail,
    required this.initials,
    required this.tint,
  });

  final String name;
  final String meta;
  final String detail;
  final String initials;
  final Color tint;
}

enum BirthdayPriority { highlighted, standard }

enum BirthdayGroup {
  allContacts('Todos'),
  family('Familia'),
  innerCircle('Amigos');

  const BirthdayGroup(this.label);

  final String label;
}

class BirthdayContact {
  const BirthdayContact({
    required this.name,
    required this.relation,
    required this.birthday,
    required this.subtitle,
    required this.initials,
    required this.accent,
    required this.priority,
    required this.group,
    required this.heightFactor,
    this.actionIcon,
  });

  final String name;
  final String relation;
  final DateTime? birthday;
  final String subtitle;
  final String initials;
  final Color accent;
  final BirthdayPriority priority;
  final BirthdayGroup group;
  final double heightFactor;
  final IconData? actionIcon;
}

class ProfileInterest {
  const ProfileInterest({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

class QuickSparkEntry {
  const QuickSparkEntry({
    required this.dateLabel,
    required this.content,
    this.highlighted = false,
  });

  final String dateLabel;
  final String content;
  final bool highlighted;
}

class NoteDeliveryReceipt {
  const NoteDeliveryReceipt({
    required this.recipientName,
    required this.recipientLabel,
    required this.initials,
    required this.statusLabel,
    required this.accent,
  });

  final String recipientName;
  final String recipientLabel;
  final String initials;
  final String statusLabel;
  final Color accent;
}

class ContactProfile {
  const ContactProfile({
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.interests,
    required this.sparks,
  });

  final String name;
  final String subtitle;
  final String initials;
  final List<ProfileInterest> interests;
  final List<QuickSparkEntry> sparks;

  ContactProfile copyWith({
    String? name,
    String? subtitle,
    String? initials,
    List<ProfileInterest>? interests,
    List<QuickSparkEntry>? sparks,
  }) {
    return ContactProfile(
      name: name ?? this.name,
      subtitle: subtitle ?? this.subtitle,
      initials: initials ?? this.initials,
      interests: interests ?? this.interests,
      sparks: sparks ?? this.sparks,
    );
  }
}