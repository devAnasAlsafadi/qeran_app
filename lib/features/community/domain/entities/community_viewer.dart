/// Who is looking at a Community screen. Only the member-side gates (approval,
/// name, guidelines before a comment) depend on it; every other choice — the
/// menu rows, delete, block — comes from the server's flags. Block is never
/// offered to a matchmaker (D40).
enum CommunityViewer { member, matchmaker }
