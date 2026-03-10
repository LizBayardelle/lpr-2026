# Categories
[
  { name: "Loans",     slug: "loans",     description: "Hard money lending, bridge loans, and financing.",      sort: 1 },
  { name: "Lenders",   slug: "lenders",   description: "Private lending and capital deployment.",               sort: 2 },
  { name: "Investing", slug: "investing", description: "Real estate investment strategies and opportunities.",   sort: 3 },
  { name: "General",   slug: "general",   description: "Company news, market insights, and announcements.",     sort: 4 }
].each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |cat|
    cat.name        = attrs[:name]
    cat.description = attrs[:description]
    cat.sort        = attrs[:sort]
  end
end

puts "Seeded #{Category.count} categories."
