/// Route paths for the tasks feature, shared by the router (registration)
/// and the notification tap handler (navigation) so the deep-link target
/// can never drift from the registered route.
const String tasksTabPath = '/tasks';

String taskDetailPath(String taskId) => '/tasks/$taskId';
