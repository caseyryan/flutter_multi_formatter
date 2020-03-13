/// this is used in a formatAsPhoneNumber() function
/// and this is what the returned result depends on
enum InvalidPhoneAction {
  ShowUnformatted,
  ReturnNull,
  ShowPhoneInvalidString
}
/// The default separator is Braces
/// and the phone number will look like 
/// +7 (999) 888-55-55. If you use Dashes 
/// it will turn into +7-999-888-55-55
enum AreaCodeSeparator {
  Braces,
  Dashes
}