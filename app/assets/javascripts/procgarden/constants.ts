module ProcGarden {
    //
    export enum PhaseConstant {
        Waiting = 0,
        NotExecuted = 10,
        Compiling = 200,
        Compiled = 250,
        Linking = 280,
        Linked = 281,
        Running = 300,
        Finished = 400,
        Error = 401
    }

    //
    export enum StatusConstant {
        MemoryLimit = 1,
        CPULimit = 2,
        OutputLimit = 22,
        Error = 3,
        InvalidCommand = 31,
        Passed = 4,
        UnexpectedError = 5,
    }
}