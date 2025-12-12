import 'package:flutter/material.dart';
import 'components/upload.dart';
import 'components/print_history.dart';

class PrintPage extends StatelessWidget {
  const PrintPage({super.key});

  // Sample print jobs data - replace with real data from your backend/database
  static final List<PrintJob> _sampleJobs = [
    PrintJob(
      code: '01',
      fileName: 'Assignment_Chapter5.pdf',
      dateTime: DateTime(2025, 12, 10, 14, 30),
      status: PrintStatus.finished,
    ),
    PrintJob(
      code: '02',
      fileName: 'Resume_Final.docx',
      dateTime: DateTime(2025, 12, 10, 13, 15),
      status: PrintStatus.pending,
    ),
    PrintJob(
      code: '03',
      fileName: 'Project_Report.pdf',
      dateTime: DateTime(2025, 12, 9, 16, 45),
      status: PrintStatus.cancelled,
    ),
    PrintJob(
      code: '04',
      fileName: 'Thesis_Draft_v3.pdf',
      dateTime: DateTime(2025, 12, 9, 11, 20),
      status: PrintStatus.finished,
    ),
    PrintJob(
      code: '05',
      fileName: 'Notes_Lecture12.pdf',
      dateTime: DateTime(2025, 12, 8, 9, 30),
      status: PrintStatus.finished,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            const Upload(),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: PrintHistory(
                printJobs: _sampleJobs,
                onJobTap: (job) {
                  // Handle when a print job is tapped
                  print('Tapped on job: ${job.code} - ${job.fileName}');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
