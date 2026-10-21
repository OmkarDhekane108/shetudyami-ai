if (snapshot.hasData) {
  return StreamBuilder<DocumentSnapshot>(
    stream: FirebaseFirestore.instance
        .collection('users')
        .doc(snapshot.data!.uid)
        .snapshots(),
    builder: (context, doc) {
      if (!doc.hasData) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      return doc.data!.exists
          ? const HomeScreen()
          : const ProfileScreen();
    },
  );
}