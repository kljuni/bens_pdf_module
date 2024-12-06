[
  { username: 'user_1' },
  { username: 'user_2' },
  { username: 'user_3' },
  { username: 'user_4' }
].each do |user_attributes|
  User.find_or_create_by!(username: user_attributes[:username])
end
