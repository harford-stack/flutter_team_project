// 비밀번호 강도 검증 유틸리티

import 'package:flutter/material.dart';

enum PasswordStrength {
  weak,      // 약함
  fair,      // 보통
  good,      // 좋음
  strong,    // 강함
}

class PasswordValidator {
  // 비밀번호 강도 계산
  static PasswordStrength calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.weak;
    
    int strength = 0;
    
    // 길이 체크
    if (password.length >= 8) strength += 1;
    if (password.length >= 12) strength += 1;
    
    // 영문자 포함
    if (password.contains(RegExp(r'[a-z]'))) strength += 1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 1;
    
    // 숫자 포함
    if (password.contains(RegExp(r'[0-9]'))) strength += 1;
    
    // 특수문자 포함
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 1;
    
    if (strength <= 2) return PasswordStrength.weak;
    if (strength <= 3) return PasswordStrength.fair;
    if (strength <= 5) return PasswordStrength.good;
    return PasswordStrength.strong;
  }
  
  // 비밀번호 강도 텍스트
  static String getStrengthText(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return '약함';
      case PasswordStrength.fair:
        return '보통';
      case PasswordStrength.good:
        return '좋음';
      case PasswordStrength.strong:
        return '강함';
    }
  }
  
  // 비밀번호 강도 색상
  static Color getStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.fair:
        return Colors.orange;
      case PasswordStrength.good:
        return Colors.blue;
      case PasswordStrength.strong:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  // 비밀번호 규칙 키 리스트 (순서 중요)
  static List<String> getRuleKeys() {
    return ['length', 'lowercase', 'uppercase', 'number', 'special'];
  }
  
  // 비밀번호 규칙 검증
  static Map<String, bool> validateRules(String password) {
    return {
      'length': password.length >= 8,
      'lowercase': password.contains(RegExp(r'[a-z]')),
      'uppercase': password.contains(RegExp(r'[A-Z]')),
      'number': password.contains(RegExp(r'[0-9]')),
      'special': password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')),
    };
  }
  
  // 비밀번호 규칙 안내 텍스트 (getRuleKeys()의 순서와 일치)
  static List<String> getRuleTexts() {
    return [
      '8자 이상',      // 'length'
      '소문자 포함',    // 'lowercase'
      '대문자 포함',    // 'uppercase'
      '숫자 포함',      // 'number'
      '특수문자 포함',  // 'special'
    ];
  }
}

