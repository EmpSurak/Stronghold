class CommandJobStorage {
    private dictionary jobs;

    CommandJobStorage(){}

    int AddJob(int char_id){
        string char_id_str = char_id;
        int counter = 0;
        if(jobs.exists(char_id_str)){
            jobs.get(char_id_str, counter);
        }
        counter++;
        jobs.set(char_id_str, counter);
        return counter;
    }

    int GetJob(int char_id){
        string char_id_str = char_id;
        int counter = -1;
        if(jobs.exists(char_id_str)){
            jobs.get(char_id_str, counter);
        }
        return counter;
    }
}
