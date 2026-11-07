"ridesharing.st

A class-based ride sharing system in GNU Smalltalk, written as one of two
parallel implementations. The C++ version in ../cpp/ridesharing.cpp models the
same classes and prints the same output for the first three sections, so that
any difference between the two programs is attributable to the language rather
than to the design.

Run:
    gst ridesharing.st
"

"---------------------------------------------------------------- formatting

Smalltalk has no printf. These helpers build the fixed-width strings by hand so
that the output matches the C++ version character for character."

Object subclass: RideFormat [
    RideFormat class >> money: amount [
        | cents whole frac |
        cents := (amount * 100) rounded.
        whole := cents // 100.
        frac := cents \\ 100.
        ^'$', whole printString, '.',
          (frac < 10 ifTrue: ['0'] ifFalse: ['']), frac printString
    ]

    RideFormat class >> oneDecimal: value [
        | tenths whole frac |
        tenths := (value * 10) rounded.
        whole := tenths // 10.
        frac := tenths \\ 10.
        ^whole printString, '.', frac printString
    ]

    RideFormat class >> miles: distance [
        ^(self oneDecimal: distance), ' mi'
    ]

    RideFormat class >> pad: aString to: width [
        | result |
        result := aString copy.
        [result size < width] whileTrue: [result := result, ' '].
        ^result
    ]
]

"---------------------------------------------------------------- Ride

Inheritance. Ride is the base class holding the state every ride has.

Encapsulation. In Smalltalk instance variables are private to the object by
construction. There is no public option to choose, so the four variables below
are reachable only from methods of Ride and its subclasses.

Polymorphism. fare is declared here as subclassResponsibility, so every
concrete ride must supply its own pricing rule, and a caller can price a ride
without knowing which kind it holds."

Object subclass: Ride [
    | rideID pickupLocation dropoffLocation distance |

    Ride class >> id: anId from: aPickup to: aDropoff distance: aDistance [
        ^self new setId: anId from: aPickup to: aDropoff distance: aDistance
    ]

    setId: anId from: aPickup to: aDropoff distance: aDistance [
        rideID := anId.
        pickupLocation := aPickup.
        dropoffLocation := aDropoff.
        distance := aDistance.
        ^self
    ]

    id [ ^rideID ]
    distance [ ^distance ]

    "Each subclass prices itself."
    fare [ ^self subclassResponsibility ]

    "The label a subclass reports in ride details."
    rideType [ ^self subclassResponsibility ]

    "The format is shared. The parts that vary are reached through the two
     messages above, which are resolved against the receiver at run time."
    rideDetails [
        ^'[', rideID, '] ',
          (RideFormat pad: self rideType to: 8), '  ',
          pickupLocation, ' -> ', dropoffLocation, '  ',
          (RideFormat miles: distance), '  ',
          (RideFormat money: self fare)
    ]
]

"---------------------------------------------------------------- subclasses"

Ride subclass: StandardRide [
    StandardRide class >> base [ ^2.50 ]
    StandardRide class >> perMile [ ^1.75 ]

    fare [
        ^StandardRide base + (StandardRide perMile * distance)
    ]

    rideType [ ^'Standard' ]
]

Ride subclass: PremiumRide [
    PremiumRide class >> base [ ^5.00 ]
    PremiumRide class >> perMile [ ^3.20 ]
    PremiumRide class >> minimum [ ^15.00 ]

    "A premium ride costs more per mile and never settles below a floor."
    fare [
        | computed |
        computed := PremiumRide base + (PremiumRide perMile * distance).
        ^computed < PremiumRide minimum
            ifTrue: [PremiumRide minimum]
            ifFalse: [computed]
    ]

    rideType [ ^'Premium' ]
]

"---------------------------------------------------------------- Driver

Encapsulation. assignedRides is an instance variable, so nothing outside the
object can touch it. Callers add to it through addRide and read it through the
summary that getDriverInfo returns. No accessor for the collection itself is
defined, which is what the demonstration at the end of this file shows."

Object subclass: Driver [
    | driverID name rating assignedRides |

    Driver class >> id: anId name: aName rating: aRating [
        ^self new setId: anId name: aName rating: aRating
    ]

    setId: anId name: aName rating: aRating [
        driverID := anId.
        name := aName.
        rating := aRating.
        assignedRides := OrderedCollection new.
        ^self
    ]

    addRide: aRide [
        assignedRides add: aRide.
        ^self
    ]

    totalEarnings [
        ^assignedRides inject: 0 into: [:sum :ride | sum + ride fare]
    ]

    getDriverInfo [
        | info |
        info := 'Driver ', driverID, '  ', name,
                '  rating ', (RideFormat oneDecimal: rating),
                '  rides ', assignedRides size printString,
                '  earned ', (RideFormat money: self totalEarnings).
        assignedRides do: [:ride |
            info := info, (String with: Character nl), '    ', ride rideDetails].
        ^info
    ]
]

"---------------------------------------------------------------- Rider"

Object subclass: Rider [
    | riderID name requestedRides |

    Rider class >> id: anId name: aName [
        ^self new setId: anId name: aName
    ]

    setId: anId name: aName [
        riderID := anId.
        name := aName.
        requestedRides := OrderedCollection new.
        ^self
    ]

    requestRide: aRide [
        requestedRides add: aRide.
        ^self
    ]

    viewRides [
        | history |
        history := 'Rider ', riderID, '  ', name,
                   '  requested ', requestedRides size printString.
        requestedRides do: [:ride |
            history := history, (String with: Character nl), '    ', ride rideDetails].
        ^history
    ]
]

"---------------------------------------------------------------- demo"

Object subclass: RideSharingDemo [
    RideSharingDemo class >> run [
        | rides total alice marcus priya sam |

        "One collection, two concrete types. Nothing below asks what kind a
         ride is. Every fare and every detail line is dispatched on the
         receiver."
        rides := OrderedCollection new.
        rides add: (StandardRide id: 'R-1001' from: 'Union Square' to: 'Mission Bay' distance: 3.4).
        rides add: (PremiumRide  id: 'R-1002' from: 'SFO Terminal 2' to: 'Palo Alto' distance: 21.7).
        rides add: (StandardRide id: 'R-1003' from: 'Berkeley' to: 'Oakland Airport' distance: 14.2).
        rides add: (PremiumRide  id: 'R-1004' from: 'Nob Hill' to: 'Ferry Building' distance: 1.3).

        Transcript showCr: '=== All rides, priced polymorphically ==='.
        rides do: [:ride | Transcript showCr: ride rideDetails].

        total := rides inject: 0 into: [:sum :ride | sum + ride fare].
        Transcript showCr: 'Total of ', rides size printString, ' rides: ',
                           (RideFormat money: total).

        Transcript showCr: ''.
        Transcript showCr: '=== Drivers ==='.
        alice := Driver id: 'D-01' name: 'Alice Chen' rating: 4.9.
        marcus := Driver id: 'D-02' name: 'Marcus Hill' rating: 4.6.
        alice addRide: (rides at: 1); addRide: (rides at: 2).
        marcus addRide: (rides at: 3); addRide: (rides at: 4).
        Transcript showCr: alice getDriverInfo.
        Transcript showCr: marcus getDriverInfo.

        Transcript showCr: ''.
        Transcript showCr: '=== Riders ==='.
        priya := Rider id: 'U-77' name: 'Priya Raman'.
        sam := Rider id: 'U-78' name: 'Sam Oforiwa'.
        priya requestRide: (rides at: 1); requestRide: (rides at: 4).
        sam requestRide: (rides at: 2); requestRide: (rides at: 3).
        Transcript showCr: priya viewRides.
        Transcript showCr: sam viewRides.

        "Encapsulation, demonstrated rather than asserted. The C++ version
         cannot run this check at all, because the equivalent line is rejected
         by the compiler. Here the same mistake survives until it is executed."
        Transcript showCr: ''.
        Transcript showCr: '=== Encapsulation check ==='.
        [Transcript showCr: alice assignedRides printString]
            on: Error
            do: [:e |
                Transcript showCr: 'Reading assignedRides from outside failed at run time.'.
                Transcript showCr: 'Raised: ', e class name.
                Transcript showCr: 'The collection is reachable only through addRide and getDriverInfo.'].

        ^self
    ]
]

RideSharingDemo run.
