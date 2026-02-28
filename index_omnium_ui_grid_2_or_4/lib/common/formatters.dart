String fmtMinutes(int mins){ final h=mins~/60; final m=mins%60; if(h==0) return '${m}m'; if(m==0) return '${h}h'; return '${h}h ${m}m'; }
String fmtSeconds(int secs){ final m=secs~/60; final s=secs%60; return '$m:${s.toString().padLeft(2,'0')}'; }
