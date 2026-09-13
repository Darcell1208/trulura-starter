/// The outcome of reading an account's saved Vibe.
///
/// Three states on purpose. A list or a nullable string merges "read, and
/// empty" with "could not read", and a failed read must not look like an empty
/// vibe -- an empty vibe is a real state, so nothing would look wrong.
enum VibeRead { present, empty, unknown }
