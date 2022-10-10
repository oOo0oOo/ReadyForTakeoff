
# airports = ["Atlanta","Beijing","Los Angeles","Tokyo","Dubai","Chicago","London","Shanghai","Paris","Dallas","Guangzhou","Amsterdam","Hong Kong","Frankfurt","Denver","Seoul","Singapore","Delhi","Bangkok","Banten","New York","Kuala Lumpur","Madrid","San Francisco","Chengdu","Shenzhen","Barcelona","Istanbul","Seattle","Las Vegas","Orlando","Toronto","Mexico City","Charlotte","Mumbai","Taiwan","Kunming","Munich","Manila","Xianyang","London","Phoenix","Moscow","Miami","Shanghai","Houston","Sydney","Rome"]


cities = ["ATLANTA","BEIJING ","LONDON ","CHICAGO","TOKYO","LOS ANGELES","PARIS","DALLAS","FRANKFURT","HONG KONG ","DENVER ","DUBAI","JAKARTA","AMSTERDAM","MADRID","BANGKOK","NEW YORK","SINGAPORE","GUANGZHOU","LAS VEGAS","SHANGHAI","SAN FRANCISCO","PHOENIX","HOUSTON","CHARLOTTE","MIAMI ","MUNICH","KUALA LUMPUR","ROME","ISTANBUL","SYDNEY","ORLANDO","SEOUL","NEW DELHI","BARCELONA","LONDON","NEWARK","TORONTO","SHANGHAI","MINNEAPOLIS","SEATTLE","DETROIT","PHILADELPHIA","MUMBAI","SAO PAULO","MANILA","CHENGDU","BOSTON","SHENZHEN","MELBOURNE","TOKYO","PARIS","MEXICO CITY","MOSCOW","ANTALYA","TAIPEI","ZURICH","FORT LAUDERDALE","WASHINGTON","PALMA DE MALLORCA","COPENHAGEN","MOSCOW","BALTIMORE","KUNMING","VIENNA","OSLO","JEDDAH","BRISBANE","SALT LAKE CITY","DUSSELDORF","BOGOTA","MILAN","JOHANNESBURG","STOCKHOLM","MANCHESTER","CHICAGO","WASHINGTON","BRUSSELS","DUBLIN","DOHA","HANGZHOU","JEJU","VANCOUVER","BERLIN","SAN DIEGO","TAMPA","SAO PAULO","BRASILIA","SAPPORO","XIAMEN","RIYADH","FUKUOKA","RIO DE JANEIRO","HELSINKI","LISBON","ATHENS","AUCKLAND"]

cities += ["Kinshasa", 'Dakar', 'Casablanca', 'Zanzibar', 'Naples', 'Muscat', 'Mendoza', 'La Paz', 'Havana', 'Lima', 'Caracas', 'Copenhagen',
    'Buenos Aires', 'Nagoya', 'Lhasa', 'Vladivostok', 'Chennai', 'Yerevan', 'Kathmandu', "Damascus", "beirut", 'cairo',
    'vilnius', 'tehran', 'nairobi', 'phuket', 'hanoi', 'lagos', 'Tel aviv', 'surabaya', 'manado', 'fiji', 'kiribati',
    'quito', 'Reykjavik', 'anchorage', 'tenerife', 'budapest', 'montreal', 'venice', 'mandalay']


# cities = ['MARS', 'MOON', 'VENUS', 'JUPITER', 'MERCURY', 'SATURN', 'URANUS', 'CERES', 'NEPTUNE', 'PLUTO']

cities = [c.strip().title() for c in cities]

cities = [c for c in cities if len(c) <= 9]

print(len(cities))

cities = list(set(cities))
cities.sort()
print(repr(cities))
