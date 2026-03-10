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

enum BirthdayPriority { vip, standard }

enum BirthdayGroup {
  allContacts('All Contacts'),
  family('Family'),
  innerCircle('Inner Circle');

  const BirthdayGroup(this.label);

  final String label;
}

class BirthdayContact {
  const BirthdayContact({
    required this.name,
    required this.relation,
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
  final String subtitle;
  final String initials;
  final Color accent;
  final BirthdayPriority priority;
  final BirthdayGroup group;
  final double heightFactor;
  final IconData? actionIcon;
}

class SearchContact {
  const SearchContact({
    required this.name,
    required this.description,
    required this.initials,
    required this.statusColor,
    required this.highlighted,
  });

  final String name;
  final String description;
  final String initials;
  final Color statusColor;
  final bool highlighted;
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
}