package db

import (
	"errors"
	"fmt"
	"strings"
	"sync"
	"xorm/config"

	//mssql
	_ "github.com/denisenkom/go-mssqldb"
	//mysql
	_ "github.com/go-sql-driver/mysql"
	"github.com/go-xorm/xorm"
	"github.com/hsyan2008/go-logger"
	_ "github.com/lib/pq"
	"xorm/common"
)

var engineMap = new(sync.Map)

func InitDb(dbConfig config.DbConfig) (engine xorm.EngineInterface, err error) {

	var isNew bool

	engine, isNew, err = getEngine(dbConfig.DbStdConfig)
	if err != nil {
		return engine, err
	}

	var isnew bool
	var slaveEngine *xorm.Engine
	if len(dbConfig.Slaves) > 0 {
		var slaves []*xorm.Engine
		for _, val := range dbConfig.Slaves {
			slaveEngine, isnew, err = getEngine(val)
			if err != nil {
				return engine, err
			}
			isNew = isNew || isnew
			slaves = append(slaves, slaveEngine)
		}
		engine, err = xorm.NewEngineGroup(engine, slaves)
		if err != nil {
			return nil, fmt.Errorf("NewEngineGroup dbConfig: %v failed: %v", dbConfig, err)
		}
	}

	engine.SetLogger(newXormLog())
	engine.ShowSQL(true)
	engine.ShowExecTime(true)

	if isNew {
		err = engine.Ping()
		if err != nil {
			return nil, fmt.Errorf("Ping dbConfig: %v failed: %v", dbConfig, err)
		}

		//连接池的空闲数大小
		if dbConfig.MaxIdleConns > 0 {
			engine.SetMaxIdleConns(dbConfig.MaxIdleConns)
		}
		//最大打开连接数
		if dbConfig.MaxOpenConns > 0 {
			engine.SetMaxOpenConns(dbConfig.MaxOpenConns)
		}

		//go keepalive(engine, dbConfig.KeepAlive)
	}

	return engine, nil
}

func getEngine(config config.DbStdConfig) (engine *xorm.Engine, isNew bool, err error) {

	if config.Driver == "" {
		err = errors.New("dbConfig Driver is nil")
		return
	}

	driver := config.Driver
	dbDsn := getDbDsn(config)

	if e, ok := engineMap.Load(common.Md5(dbDsn)); ok {
		return e.(*xorm.Engine), isNew, nil
	}

	logger.Info("dbDsn:", dbDsn)

	engine, err = xorm.NewEngine(driver, dbDsn)
	if err != nil {
		return engine, isNew, fmt.Errorf("NewEngine dbConfig: %v failed: %v", config, err)
	}

	engineMap.Store(common.Md5(dbDsn), engine)
	isNew = true

	return
}

func getDbDsn(dbConfig config.DbStdConfig) string {
	switch strings.ToLower(dbConfig.Driver) {
	case "mysql":
		if dbConfig.Port != "" {
			dbConfig.Address = fmt.Sprintf("%s:%s", dbConfig.Address, dbConfig.Port)
		}
		return fmt.Sprintf("%s:%s@%s(%s)/%s%s",
			dbConfig.Username, dbConfig.Password, dbConfig.Protocol,
			dbConfig.Address, dbConfig.Dbname, dbConfig.Params)
	case "mssql", "sqlserver":
		return fmt.Sprintf("odbc:user id=%s;password=%s;server=%s;port=%s;database=%s;%s",
			dbConfig.Username, dbConfig.Password, dbConfig.Address, dbConfig.Port,
			dbConfig.Dbname, dbConfig.Params)
	case "postgres":
		// if dbConfig.Port != "" {
		// 	dbConfig.Address = fmt.Sprintf("%s:%s", dbConfig.Address, dbConfig.Port)
		// }
		// return fmt.Sprintf("postgres://%s:%s@%s/%s%s",
		// 	dbConfig.Username, dbConfig.Password, dbConfig.Address, dbConfig.Dbname, dbConfig.Params)
		return fmt.Sprintf("host=%s port=%s user=%s password='%s' dbname=%s %s",
			dbConfig.Address, dbConfig.Port, dbConfig.Username, dbConfig.Password,
			dbConfig.Dbname, dbConfig.Params)
	default:
		panic("error db driver")
	}
}

//func keepalive(engine xorm.EngineInterface, long time.Duration) {
//	if long <= 0 {
//		return
//	}
//	t := time.Tick(long * time.Second)
//	ctx := signal.GetSignalContext()
//FOR:
//	for {
//		select {
//		case <-t:
//			_ = engine.Ping()
//		case <-ctx.Ctx.Done():
//			break FOR
//		}
//	}
//}
