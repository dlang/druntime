module core.stdcpp.stl_pair;

version (CRuntime_Glibc) {
	extern (C++, std) struct pair(T1, T2) {

		alias first_type = T1;
		alias second_type = T2;

		T1 first;
		T2 second;

		this(T1 x, T2 y) { first = x; second = y; }

		this(U1, U2)(auto ref U1 x, auto ref U2 y) {
			if (isConvertible!(U1, T1) && isConvertible!(U2, T2)) {
				first = x;
				second = y;
			}
		}

		this(U1, U2)(auto ref pair!(U1,  U2) p) {
			first = p.first; second = p.second;
		}

		this(U1, U2)(auto ref const pair!(U1,  U2) p) {
			first = p.first; second = p.second;
		}

		void swap(ref pair rhs);

		void opAssign(U1, U2)(auto ref pair!(U1, U2) rhs) {
			first = rhs.first;
			second = rhs.second;
		}

		void opAssign(U1, U2)(auto ref const pair!(U1, U2) rhs) {
			first = rhs.first;
			second = rhs.second;
		}

		bool opEquals(P)(auto ref P rhs) {
			return first == rhs.first && second == rhs.second;
		}

		bool opEquals(P)(auto ref P rhs) const {
			return first == rhs.first && second == rhs.second;
		}

		int opCmp(P)(auto ref P rhs) {
			if (first < rhs.first) return -1;
			if (first > rhs.first) return 1;
			return second < rhs.second ? -1 : second > rhs.second;
		}
		int opCmp(P)(auto ref P rhs) const {
			if (first < rhs.first) return -1;
			if (first > rhs.first) return 1;
			return second < rhs.second ? -1 : second > rhs.second;
		}

		// WIP: attempt just link without implementation, mangling issues
		pair!(T1, T2) make_pair(T1, T2)(auto ref T1 v1, auto ref T2 v2)
		{ return pair!(T1, T2)(v1, v2);}

	}
}
