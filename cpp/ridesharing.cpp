// ridesharing.cpp
//
// A class-based ride sharing system in C++, written as one of two parallel
// implementations. The Smalltalk version in ../smalltalk/ridesharing.st models
// the same classes and prints the same output, so that any difference between
// the two programs is attributable to the language rather than to the design.
//
// Build and run:
//     g++ -std=c++17 -Wall -Wextra -o ridesharing ridesharing.cpp
//     ./ridesharing

#include <iomanip>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

// ---------------------------------------------------------------- helpers

static std::string money(double amount)
{
    std::ostringstream out;
    out << std::fixed << std::setprecision(2) << amount;
    return "$" + out.str();
}

static std::string miles(double distance)
{
    std::ostringstream out;
    out << std::fixed << std::setprecision(1) << distance;
    return out.str() + " mi";
}

// ---------------------------------------------------------------- Ride
//
// Inheritance. Ride is the base class holding the state every ride has.
// Encapsulation. The data members are protected rather than public, so a
// subclass can read them but nothing outside the hierarchy can reach past the
// accessors.
// Polymorphism. fare() is pure virtual, which forces every concrete ride to
// supply its own pricing rule and lets a caller price a ride without knowing
// which kind it holds.

class Ride {
protected:
    std::string rideID;
    std::string pickupLocation;
    std::string dropoffLocation;
    double distance;   // miles

public:
    Ride(std::string id, std::string pickup, std::string dropoff, double dist)
        : rideID(std::move(id)), pickupLocation(std::move(pickup)),
          dropoffLocation(std::move(dropoff)), distance(dist) {}

    virtual ~Ride() = default;

    // Each subclass prices itself.
    virtual double fare() const = 0;

    // The label a subclass reports in ride details.
    virtual std::string rideType() const = 0;

    const std::string& id() const { return rideID; }
    double getDistance() const { return distance; }

    // Not virtual. The format is shared, and the parts that vary are reached
    // through the two virtual calls above.
    std::string rideDetails() const
    {
        std::string label = rideType();
        label.resize(8, ' ');          // keeps the columns aligned
        return "[" + rideID + "] " + label + "  " +
               pickupLocation + " -> " + dropoffLocation +
               "  " + miles(distance) + "  " + money(fare());
    }
};

// ---------------------------------------------------------------- subclasses

class StandardRide : public Ride {
    static constexpr double BASE = 2.50;
    static constexpr double PER_MILE = 1.75;

public:
    using Ride::Ride;

    double fare() const override
    {
        return BASE + PER_MILE * distance;
    }

    std::string rideType() const override { return "Standard"; }
};

class PremiumRide : public Ride {
    static constexpr double BASE = 5.00;
    static constexpr double PER_MILE = 3.20;
    static constexpr double MINIMUM = 15.00;

public:
    using Ride::Ride;

    // A premium ride costs more per mile and never settles below a floor.
    double fare() const override
    {
        double computed = BASE + PER_MILE * distance;
        return computed < MINIMUM ? MINIMUM : computed;
    }

    std::string rideType() const override { return "Premium"; }
};

// ---------------------------------------------------------------- Driver
//
// Encapsulation. assignedRides is private. Callers add to it only through
// addRide, and read it only through the summary that getDriverInfo returns, so
// the class controls every change to its own state.

class Driver {
    std::string driverID;
    std::string name;
    double rating;
    std::vector<std::shared_ptr<Ride>> assignedRides;

public:
    Driver(std::string id, std::string n, double r)
        : driverID(std::move(id)), name(std::move(n)), rating(r) {}

    void addRide(const std::shared_ptr<Ride>& ride)
    {
        assignedRides.push_back(ride);
    }

    double totalEarnings() const
    {
        double sum = 0.0;
        for (const auto& ride : assignedRides) {
            sum += ride->fare();   // resolved at run time, per ride
        }
        return sum;
    }

    std::string getDriverInfo() const
    {
        std::ostringstream out;
        out << std::fixed << std::setprecision(1) << rating;
        std::string info = "Driver " + driverID + "  " + name +
                           "  rating " + out.str() +
                           "  rides " + std::to_string(assignedRides.size()) +
                           "  earned " + money(totalEarnings());
        for (const auto& ride : assignedRides) {
            info += "\n    " + ride->rideDetails();
        }
        return info;
    }
};

// ---------------------------------------------------------------- Rider

class Rider {
    std::string riderID;
    std::string name;
    std::vector<std::shared_ptr<Ride>> requestedRides;

public:
    Rider(std::string id, std::string n)
        : riderID(std::move(id)), name(std::move(n)) {}

    void requestRide(const std::shared_ptr<Ride>& ride)
    {
        requestedRides.push_back(ride);
    }

    std::string viewRides() const
    {
        std::string history = "Rider " + riderID + "  " + name +
                              "  requested " +
                              std::to_string(requestedRides.size());
        for (const auto& ride : requestedRides) {
            history += "\n    " + ride->rideDetails();
        }
        return history;
    }
};

// ---------------------------------------------------------------- demo

int main()
{
    // One list, two concrete types. Nothing below asks what kind a ride is.
    std::vector<std::shared_ptr<Ride>> rides = {
        std::make_shared<StandardRide>("R-1001", "Union Square", "Mission Bay", 3.4),
        std::make_shared<PremiumRide>("R-1002", "SFO Terminal 2", "Palo Alto", 21.7),
        std::make_shared<StandardRide>("R-1003", "Berkeley", "Oakland Airport", 14.2),
        std::make_shared<PremiumRide>("R-1004", "Nob Hill", "Ferry Building", 1.3),
    };

    std::cout << "=== All rides, priced polymorphically ===\n";
    for (const auto& ride : rides) {
        std::cout << ride->rideDetails() << "\n";
    }

    double total = 0.0;
    for (const auto& ride : rides) {
        total += ride->fare();
    }
    std::cout << "Total of " << rides.size() << " rides: " << money(total) << "\n";

    std::cout << "\n=== Drivers ===\n";
    Driver alice("D-01", "Alice Chen", 4.9);
    Driver marcus("D-02", "Marcus Hill", 4.6);
    alice.addRide(rides[0]);
    alice.addRide(rides[1]);
    marcus.addRide(rides[2]);
    marcus.addRide(rides[3]);
    std::cout << alice.getDriverInfo() << "\n";
    std::cout << marcus.getDriverInfo() << "\n";

    std::cout << "\n=== Riders ===\n";
    Rider priya("U-77", "Priya Raman");
    Rider sam("U-78", "Sam Oforiwa");
    priya.requestRide(rides[0]);
    priya.requestRide(rides[3]);
    sam.requestRide(rides[1]);
    sam.requestRide(rides[2]);
    std::cout << priya.viewRides() << "\n";
    std::cout << sam.viewRides() << "\n";

    // Encapsulation. The line below does not compile, because assignedRides
    // is private. A caller can only change a driver's rides through addRide.
    //
    //     alice.assignedRides.push_back(rides[0]);
    //     error: 'std::vector<std::shared_ptr<Ride> > Driver::assignedRides'
    //            is private within this context

    return 0;
}
