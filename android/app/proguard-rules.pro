# Room instantiates the generated *_Impl database class reflectively via
# Class.newInstance(). R8 does not see that call, so it strips the no-arg
# constructor and instantiation fails at runtime with:
#   RuntimeException: Failed to create an instance of androidx.work.impl.WorkDatabase
#
# This hits us through google_mobile_ads -> play-services-ads -> androidx.work
# -> androidx.room 2.2.5, which is too old to ship its own consumer rules.
# The crash happens in androidx.startup's InitializationProvider, i.e. before
# Application.onCreate, so the release build dies on launch.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-dontwarn androidx.room.paging.**
