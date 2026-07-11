import 'package:flutter/material.dart';
import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FdcGridColumnGroup', () {
    test('behaves as a value object', () {
      const group = FdcGridColumnGroup(id: 'customer', label: 'Customer');
      const sameGroup = FdcGridColumnGroup(id: 'customer', label: 'Customer');

      expect(group, sameGroup);
      expect(group.hashCode, sameGroup.hashCode);
      expect(
        group,
        isNot(const FdcGridColumnGroup(id: 'financial', label: 'Financial')),
      );
    });

    test('includes every public field in equality', () {
      const base = FdcGridColumnGroup(id: 'customer', label: 'Customer');

      expect(
        base,
        isNot(const FdcGridColumnGroup(id: 'client', label: 'Customer')),
      );
      expect(
        base,
        isNot(const FdcGridColumnGroup(id: 'customer', label: 'Client')),
      );
      expect(
        base,
        isNot(
          const FdcGridColumnGroup(
            id: 'customer',
            label: 'Customer',
            style: FdcGridColumnGroupStyle(backgroundColor: Colors.amber),
          ),
        ),
      );
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcGridColumnGroup(id: 'customer', label: 'Customer');

      expect(base.copyWith(), base);
      expect(
        base.copyWith(id: 'client'),
        const FdcGridColumnGroup(id: 'client', label: 'Customer'),
      );
      expect(
        base.copyWith(label: 'Client'),
        const FdcGridColumnGroup(id: 'customer', label: 'Client'),
      );
      expect(
        base.copyWith(id: 'client', label: 'Client'),
        const FdcGridColumnGroup(id: 'client', label: 'Client'),
      );
      expect(
        base.copyWith(
          style: const FdcGridColumnGroupStyle(backgroundColor: Colors.amber),
        ),
        const FdcGridColumnGroup(
          id: 'customer',
          label: 'Customer',
          style: FdcGridColumnGroupStyle(backgroundColor: Colors.amber),
        ),
      );
    });
  });

  group('FdcGridColumnGroupStyle', () {
    test('behaves as a value object', () {
      const style = FdcGridColumnGroupStyle(
        backgroundColor: Colors.blue,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 12),
        bottomSeparatorColor: Colors.black,
        verticalSeparatorColor: Colors.red,
        verticalSeparatorInset: 2,
      );

      const sameStyle = FdcGridColumnGroupStyle(
        backgroundColor: Colors.blue,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 12),
        bottomSeparatorColor: Colors.black,
        verticalSeparatorColor: Colors.red,
        verticalSeparatorInset: 2,
      );

      expect(style, sameStyle);
      expect(style.hashCode, sameStyle.hashCode);
      expect(style, isNot(style.copyWith(backgroundColor: Colors.green)));
    });

    test('copyWith keeps omitted values and replaces provided values', () {
      const base = FdcGridColumnGroupStyle(
        backgroundColor: Colors.blue,
        textStyle: TextStyle(fontWeight: FontWeight.bold),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: 12),
        bottomSeparatorColor: Colors.black,
        verticalSeparatorColor: Colors.red,
        verticalSeparatorInset: 2,
      );

      expect(base.copyWith(), base);
      expect(
        base.copyWith(backgroundColor: Colors.green),
        const FdcGridColumnGroupStyle(
          backgroundColor: Colors.green,
          textStyle: TextStyle(fontWeight: FontWeight.bold),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 12),
          bottomSeparatorColor: Colors.black,
          verticalSeparatorColor: Colors.red,
          verticalSeparatorInset: 2,
        ),
      );
    });
  });
}
