import 'package:essentials/essentials.dart';
import 'package:flutter/material.dart';

import '../bloc/sample_bloc.dart';

class SamplePage extends StatelessWidget {
  const SamplePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SampleBloc>(
      create: (_) => ApplicationContainer.resolve<SampleBloc>()..add(SampleStarted()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Sample Feature'),
        ),
        body: BlocBuilder<SampleBloc, SampleState>(
          builder: (context, state) {
            return switch (state) {
              SampleInitial() || SampleLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
              SampleLoaded(:final items) => ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item.name),
                    );
                  },
                ),
              SampleError(:final message) => Center(
                  child: Text(message),
                ),
            };
          },
        ),
      ),
    );
  }
}
